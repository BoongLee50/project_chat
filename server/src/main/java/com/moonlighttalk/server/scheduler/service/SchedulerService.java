package com.moonlighttalk.server.scheduler.service;

import com.moonlighttalk.server.auth.service.SessionTimeService;
import com.moonlighttalk.server.chat.entity.ChatRoom;
import com.moonlighttalk.server.chat.socket.Opcodes;
import com.moonlighttalk.server.chat.socket.Packet;
import com.moonlighttalk.server.chat.socket.SocketRegistry;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.comment.mapper.CommentMapper;
import com.moonlighttalk.server.dailyquestion.mapper.DailyQuestionMapper;
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
    private final CommentMapper commentMapper;
    private final DailyQuestionMapper dailyQuestionMapper;

    private final int retentionDays;
    private final int retentionBatchSize;

    public SchedulerService(SchedulerMapper schedulerMapper,
                             SocketRegistry socketRegistry,
                             FileStorageService fileStorageService,
                             SessionTimeService sessionTime,
                             MessageRetentionPurger messageRetentionPurger,
                             StoreMapper storeMapper,
                             CommentMapper commentMapper,
                             DailyQuestionMapper dailyQuestionMapper,
                             @Value("${app.chat.retention-days:30}") int retentionDays,
                             @Value("${app.chat.retention-batch-size:1000}") int retentionBatchSize) {
        this.schedulerMapper = schedulerMapper;
        this.socketRegistry = socketRegistry;
        this.fileStorageService = fileStorageService;
        this.sessionTime = sessionTime;
        this.messageRetentionPurger = messageRetentionPurger;
        this.storeMapper = storeMapper;
        this.commentMapper = commentMapper;
        this.dailyQuestionMapper = dailyQuestionMapper;
        this.retentionDays = retentionDays;
        this.retentionBatchSize = retentionBatchSize;
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
        // 노출 기록은 15분 판정용이라 하루가 지나면 쓸모가 없다(V12).
        int exposures = schedulerMapper.deleteExposuresBefore(
                sessionTime.nowKst().toLocalDateTime().minusDays(1));
        int usage = schedulerMapper.deleteDailyUsageBefore(today);
        int posts = schedulerMapper.deleteStalePosts(today);
        // 달빛 한마디는 18시에 초기화된다 — 지난 영업일 답변을 치운다(질문·좋아요는 FK로 따라간다).
        int answers = dailyQuestionMapper.deleteAnswersBefore(today);
        // 포스트·답변이 지워져도 댓글은 남는다 — V14에서 대상이 두 종류가 되며 FK가 사라졌다.
        int orphanComments = commentMapper.deleteOrphans(today);

        log.info("[배치] 지난 영업일 정리(<{}) 사진 {}건(파일 실패 {}) · 스코어 {} · 스킵 {} · 노출 {} · 일일사용량 {} · 포스트 {} · 한마디 {} · 고아댓글 {}",
                today, photos, failed, stats, skips, exposures, usage, posts,
                answers, orphanComments);
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
     * 보관 기간이 지난 메시지 삭제(FIFO). <b>방 타입과 무관하게 30일</b>(기획 답변 2026-09-06).
     *
     * <p>예전엔 친구 방만 1년이었는데 "친구방이라는 개념이 따로 있는 게 아니다"로 정리됐다.
     *
     * <p>한 트랜잭션에 수백만 행을 담지 않도록 배치 크기만큼 끊어서 지운다
     * (트랜잭션 단위는 {@link MessageRetentionPurger}).
     */
    public int purgeExpiredMessages() {
        LocalDateTime before = LocalDateTime.now().minusDays(retentionDays);

        int total = 0;
        while (true) {
            int deleted = messageRetentionPurger.purgeBatch(before, retentionBatchSize);
            total += deleted;
            if (deleted < retentionBatchSize) {
                break;
            }
        }
        log.info("[배치] 보관 만료 메시지 삭제 {}건 ({}일 이전)", total, retentionDays);
        return total;
    }

    /**
     * <b>비어 버린 대화방을 닫는다</b>(기획 답변 2026-09-06).
     *
     * <p>규칙: <b>방 안에 채팅 로그가 하나도 남지 않으면 그 방은 사라진다.</b>
     * 메시지가 30일 뒤 사라지므로, 30일간 아무 대화가 없으면 방이 저절로 비게 된다.
     *
     * <p>🚨 <b>"갓 만든 방"과 "로그가 다 사라진 방"은 DB에서 구분되지 않는다</b> — 둘 다 0건이다.
     * 그래서 <b>마지막 메시지 시각(없으면 방 생성 시각)</b>을 기준으로 삼는다.
     * 이러면 기획이 말한 "처음 만들어질 때는 예외"가 규칙 안에 자연히 들어간다 —
     * 새 방도 똑같이 30일을 받고, 그동안 한마디도 없으면 그때 닫힌다.
     * (0건인 방만 지우게 짜면 방을 만든 직후 배치가 돌 때 바로 닫혀 버린다)
     *
     * <p>지우지 않고 <b>ENDED로 닫는다.</b> `active_pair_key`를 비워 같은 상대와 다시
     * 방을 만들 수 있게 한다 — 친구든 매칭이든 필요하면 새 방이 생긴다.
     * 행을 남기는 이유는 이력(신고·번역 자리)이 방 id에 걸려 있기 때문이다.
     */
    public int closeEmptyRooms() {
        LocalDateTime now = LocalDateTime.now();
        List<ChatRoom> rooms = schedulerMapper.selectRoomsIdleSince(now.minusDays(retentionDays));

        for (ChatRoom room : rooms) {
            schedulerMapper.endRoom(room.getId(), now);
            Packet packet = Packet.of(Opcodes.ROOM_STATE,
                    Map.of("roomId", room.getId(), "state", "ended"));
            socketRegistry.sendTo(room.getUserA(), packet);
            socketRegistry.sendTo(room.getUserB(), packet);
        }
        log.info("[배치] 비어 버린 대화방 종료 {}건 ({}일 무대화)", rooms.size(), retentionDays);
        return rooms.size();
    }
}
