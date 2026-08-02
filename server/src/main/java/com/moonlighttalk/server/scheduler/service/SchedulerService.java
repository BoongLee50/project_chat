package com.moonlighttalk.server.scheduler.service;

import com.moonlighttalk.server.auth.service.GateService;
import com.moonlighttalk.server.chat.entity.ChatRoom;
import com.moonlighttalk.server.chat.socket.Opcodes;
import com.moonlighttalk.server.chat.socket.Packet;
import com.moonlighttalk.server.chat.socket.SocketRegistry;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.scheduler.mapper.SchedulerMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 배치 본체. 스케줄 트리거는 {@link com.moonlighttalk.server.scheduler.ScheduledJobs}에 있고
 * 여기서는 실제 작업만 한다(수동 실행·테스트가 쉬워진다).
 *
 * <p>운영시간은 17:00 개방 ~ 06:00 종료(Plan_2). 단 <b>친구 대화방(type=FRIEND)은 24시간 예외</b>라
 * 종료·정리 대상에서 모두 빠진다. (02 문서 §4)
 */
@Service
public class SchedulerService {

    private static final Logger log = LoggerFactory.getLogger(SchedulerService.class);

    private final SchedulerMapper schedulerMapper;
    private final SocketRegistry socketRegistry;
    private final FileStorageService fileStorageService;
    private final GateService gateService;

    public SchedulerService(SchedulerMapper schedulerMapper,
                             SocketRegistry socketRegistry,
                             FileStorageService fileStorageService,
                             GateService gateService) {
        this.schedulerMapper = schedulerMapper;
        this.socketRegistry = socketRegistry;
        this.fileStorageService = fileStorageService;
        this.gateService = gateService;
    }

    /**
     * 06:00 종료 — 매칭 대화방을 모두 닫고 참여자에게 알린다.
     * 친구 방은 건드리지 않으므로, 친구끼리는 낮에도 대화가 이어진다.
     */
    @Transactional
    public int closeMatchRooms() {
        List<ChatRoom> rooms = schedulerMapper.selectActiveMatchRooms();
        if (rooms.isEmpty()) {
            log.info("[배치] 종료할 매칭 대화방 없음");
            return 0;
        }

        int ended = schedulerMapper.endAllActiveMatchRooms(LocalDateTime.now());

        for (ChatRoom room : rooms) {
            Packet packet = Packet.of(Opcodes.ROOM_STATE, Map.of(
                    "roomId", room.getId(), "state", "ended"));
            socketRegistry.sendTo(room.getUserA(), packet);
            socketRegistry.sendTo(room.getUserB(), packet);
        }
        log.info("[배치] 매칭 대화방 종료 {}건", ended);
        return ended;
    }

    /** 06:00 종료 안내 — 접속 중인 모두에게 브로드캐스트. 친구 대화는 계속 가능하다. */
    public void broadcastSystemClose() {
        socketRegistry.broadcast(Packet.of(Opcodes.SYSTEM_CLOSE, Map.of(
                "closeAt", LocalDateTime.now().toString(),
                "friendRoomsOpen", true)));
    }

    /**
     * 지난 영업일 데이터 정리. 사진은 스토리지 파일을 먼저 지우고 행을 지운다
     * (반대 순서면 행만 사라지고 파일이 고아로 남는다).
     */
    @Transactional
    public void cleanupPreviousSessions() {
        LocalDate today = gateService.currentSessionDate();

        List<String> keys = schedulerMapper.selectPhotoKeysBefore(today);
        int failed = 0;
        for (String key : keys) {
            try {
                fileStorageService.delete(key);
            } catch (RuntimeException e) {
                // 파일 하나 때문에 배치 전체를 멈추지 않는다. 행은 지우고 로그만 남긴다.
                failed++;
                log.warn("[배치] 사진 파일 삭제 실패 key={} : {}", key, e.toString());
            }
        }

        int photos = schedulerMapper.deletePhotosBefore(today);
        int stats = schedulerMapper.deleteStatsBefore(today);
        int skips = schedulerMapper.deleteSkipsBefore(today);
        int usage = schedulerMapper.deleteDailyUsageBefore(today);
        int posts = schedulerMapper.deleteStalePosts(today);

        log.info("[배치] 지난 영업일 정리(<{}) 사진 {}건(파일 실패 {}) · 스코어 {} · 스킵 {} · 일일사용량 {} · 포스트 {}",
                today, photos, failed, stats, skips, usage, posts);
    }
}
