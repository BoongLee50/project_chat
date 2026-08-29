package com.moonlighttalk.server.scheduler.service;

import com.moonlighttalk.server.auth.service.SessionTimeService;
import com.moonlighttalk.server.chat.entity.ChatRoom;
import com.moonlighttalk.server.chat.socket.Opcodes;
import com.moonlighttalk.server.chat.socket.Packet;
import com.moonlighttalk.server.chat.socket.SocketRegistry;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.scheduler.mapper.SchedulerMapper;
import com.moonlighttalk.server.store.mapper.StoreMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
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
    private final SessionTimeService sessionTime;
    private final MessageRetentionPurger messageRetentionPurger;
    private final StoreMapper storeMapper;

    private final int retentionDays;
    private final int retentionDaysFriend;
    private final int retentionBatchSize;

    public SchedulerService(SchedulerMapper schedulerMapper,
                             SocketRegistry socketRegistry,
                             FileStorageService fileStorageService,
                             SessionTimeService sessionTime,
                             MessageRetentionPurger messageRetentionPurger,
                             StoreMapper storeMapper,
                             @Value("${app.chat.retention-days:30}") int retentionDays,
                             @Value("${app.chat.retention-days-friend:365}") int retentionDaysFriend,
                             @Value("${app.chat.retention-batch-size:1000}") int retentionBatchSize) {
        this.schedulerMapper = schedulerMapper;
        this.socketRegistry = socketRegistry;
        this.fileStorageService = fileStorageService;
        this.sessionTime = sessionTime;
        this.messageRetentionPurger = messageRetentionPurger;
        this.storeMapper = storeMapper;
        this.retentionDays = retentionDays;
        this.retentionDaysFriend = retentionDaysFriend;
        this.retentionBatchSize = retentionBatchSize;
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
        LocalDate today = sessionTime.currentSessionDate();

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
        schedulerMapper.clearMainPhotosBefore(today);
        int stats = schedulerMapper.deleteStatsBefore(today);
        int skips = schedulerMapper.deleteSkipsBefore(today);
        int usage = schedulerMapper.deleteDailyUsageBefore(today);
        int translateTargets = schedulerMapper.deleteTranslateTargetsBefore(today);
        int posts = schedulerMapper.deleteStalePosts(today);

        log.info("[배치] 지난 영업일 정리(<{}) 사진 {}건(파일 실패 {}) · 스코어 {} · 스킵 {} · 일일사용량 {} · 번역상대 {} · 포스트 {}",
                today, photos, failed, stats, skips, usage, translateTargets, posts);
    }

    /**
     * BM 만료 정리 — 기간이 끝난 구독·엔티틀먼트·부스트를 치운다.
     *
     * <p>혜택 판정 자체는 {@code expires_at > now}로 하므로 이 배치가 늦어도 권한이 새지는 않는다.
     * 다만 구독은 {@code active_user_id}를 비워 줘야 다음 구독을 만들 수 있어 이쪽이 중요하다.
     */
    @Transactional
    public void expireBenefits() {
        LocalDateTime now = LocalDateTime.now();
        int subscriptions = storeMapper.expireSubscriptions(now);
        int entitlements = storeMapper.deleteExpiredEntitlements(now);
        int boosts = storeMapper.deleteExpiredBoostActivations(now);
        log.info("[배치] BM 만료 정리 구독 {} · 권리 {} · 부스트 {}", subscriptions, entitlements, boosts);
    }

    /**
     * 보관 기간이 지난 메시지 삭제(FIFO). 기준은 <b>방 타입</b> — 매칭 30일 / 친구 1년.
     * 친구를 끊어 ENDED가 된 방도 {@code type=FRIEND}라 1년 기준을 그대로 받는다.
     *
     * <p>한 트랜잭션에 수백만 행을 담지 않도록 배치 크기만큼 끊어서 지운다
     * (트랜잭션 단위는 {@link MessageRetentionPurger}).
     */
    public int purgeExpiredMessages() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime matchBefore = now.minusDays(retentionDays);
        LocalDateTime friendBefore = now.minusDays(retentionDaysFriend);

        int total = 0;
        while (true) {
            int deleted = messageRetentionPurger.purgeBatch(matchBefore, friendBefore, retentionBatchSize);
            total += deleted;
            if (deleted < retentionBatchSize) {
                break;
            }
        }
        log.info("[배치] 보관 만료 메시지 삭제 {}건 (매칭 {}일 이전 · 친구 {}일 이전)",
                total, retentionDays, retentionDaysFriend);
        return total;
    }
}
