package com.moonlighttalk.server.scheduler;

import com.moonlighttalk.server.scheduler.service.SchedulerService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 배치 트리거. 시각은 KST 고정이며 <b>{@code app.gate.*}와 반드시 같은 값</b>이어야 한다
 * (게이트 판정은 GateService, 배치 시각은 cron이라 두 곳에 있다).
 *
 * <p>범위: 게이트 개방/종료 + 지난 영업일 정리 + 메시지 보관 만료 + 프레즌스 청소.
 * BM(부스트·엔타이틀먼트·구독) 만료 정리는 아직 없다 — 07 문서 §5 참고.
 */
@Component
public class ScheduledJobs {

    private static final Logger log = LoggerFactory.getLogger(ScheduledJobs.class);
    private static final String KST = "Asia/Seoul";

    private final SchedulerService schedulerService;

    public ScheduledJobs(SchedulerService schedulerService) {
        this.schedulerService = schedulerService;
    }

    /** 17:00 개방. 게이트 판정 자체는 시간 계산이라 별도 상태 변경이 없고, 기록만 남긴다. */
    @Scheduled(cron = "${app.scheduler.gate-open-cron:0 0 17 * * *}", zone = KST)
    public void gateOpen() {
        log.info("[배치] 서비스 개방(17시)");
    }

    /** 06:00 종료 — 매칭 대화방을 닫고 접속자에게 알린다. 친구 대화방은 대상이 아니다. */
    @Scheduled(cron = "${app.scheduler.gate-close-cron:0 0 6 * * *}", zone = KST)
    public void gateClose() {
        schedulerService.closeMatchRooms();
        schedulerService.broadcastSystemClose();
    }

    /**
     * 06:05 지난 영업일 정리. 종료 처리와 같은 06:00에 겹치면 영업일 경계에서
     * {@code currentSessionDate()}가 막 넘어가는 순간과 부딪히므로 몇 분 뒤에 돈다.
     */
    @Scheduled(cron = "${app.scheduler.daily-cleanup-cron:0 5 6 * * *}", zone = KST)
    public void dailyCleanup() {
        schedulerService.cleanupPreviousSessions();
    }

    /**
     * 06:20 보관 만료 메시지 삭제(FIFO). 매칭 30일 / 친구 1년 — 판정은 방 타입 기준.
     * 정리 배치와 겹치지 않게 뒤로 뺐다.
     */
    @Scheduled(cron = "${app.scheduler.message-retention-cron:0 20 6 * * *}", zone = KST)
    public void purgeExpiredMessages() {
        schedulerService.purgeExpiredMessages();
    }
}
