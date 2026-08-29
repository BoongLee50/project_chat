package com.moonlighttalk.server.scheduler;

import com.moonlighttalk.server.garden.service.FeedSessionStore;
import com.moonlighttalk.server.scheduler.service.SchedulerService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 배치 트리거. 시각은 KST 고정이며 <b>영업일 경계({@code app.session.rollover-hour})와 맞춰야 한다</b>
 * (경계 판정은 {@code SessionTimeService}, 배치 시각은 cron이라 두 곳에 있다).
 *
 * <p>범위: 지난 영업일 정리 + 메시지 보관 만료 + BM 만료 정리(+ 프레즌스 청소는 별도).
 *
 * <p>⚠️ Plan_3에서 게이트가 폐지되며 <b>17시 개방·06시 매칭방 일괄 종료 잡이 사라졌다.</b>
 * 그래서 지금은 <b>매칭 대화방이 저절로 닫히지 않는다</b> — 신고·차단·나가기로만 닫힌다.
 * 종료 규칙은 기획 확인 대기 중이며, 필요하면 {@code SchedulerService.closeMatchRooms()}가
 * 그대로 남아 있으니 잡만 다시 달면 된다(개발용 수동 실행 엔드포인트도 유지).
 */
@Component
public class ScheduledJobs {

    private static final Logger log = LoggerFactory.getLogger(ScheduledJobs.class);
    private static final String KST = "Asia/Seoul";

    private final SchedulerService schedulerService;
    private final FeedSessionStore feedSessions;

    public ScheduledJobs(SchedulerService schedulerService, FeedSessionStore feedSessions) {
        this.schedulerService = schedulerService;
        this.feedSessions = feedSessions;
    }

    /**
     * 지난 영업일 정리. 경계 정각에 돌리면 {@code currentSessionDate()}가 막 넘어가는 순간과
     * 부딪히므로 몇 분 뒤에 돈다.
     */
    @Scheduled(cron = "${app.scheduler.daily-cleanup-cron:0 5 18 * * *}", zone = KST)
    public void dailyCleanup() {
        schedulerService.cleanupPreviousSessions();
    }

    /**
     * 보관 만료 메시지 삭제(FIFO). 매칭 30일 / 친구 1년 — 판정은 방 타입 기준.
     * 정리 배치와 겹치지 않게 뒤로 뺐다.
     */
    @Scheduled(cron = "${app.scheduler.message-retention-cron:0 20 18 * * *}", zone = KST)
    public void purgeExpiredMessages() {
        schedulerService.purgeExpiredMessages();
    }

    /**
     * BM 만료 정리(구독·엔티틀먼트·부스트). 부스트는 1시간짜리라 하루 한 번으로는 느려
     * 10분마다 돈다. 판정은 expires_at으로 하므로 늦어도 권한이 새지는 않는다.
     */
    @Scheduled(fixedDelayString = "${app.scheduler.benefit-expiry-ms:600000}")
    public void expireBenefits() {
        schedulerService.expireBenefits();
    }

    /**
     * 만료된 피드 순서를 메모리에서 치운다(③단계).
     *
     * <p>조회할 때도 TTL을 보므로 이게 없어도 잘못된 순서가 나가지는 않는다. 다만
     * <b>다시 들어오지 않는 사용자의 순서가 계속 남는다</b> — 그것만 정리하는 잡이다.
     */
    @Scheduled(fixedDelayString = "${app.scheduler.feed-session-evict-ms:600000}")
    public void evictFeedSessions() {
        int evicted = feedSessions.evictExpired();
        if (evicted > 0) {
            log.debug("[배치] 만료된 피드 순서 {}건 정리", evicted);
        }
    }
}
