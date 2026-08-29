package com.moonlighttalk.server.scheduler.controller;

import com.moonlighttalk.server.common.security.CurrentUserId;
import com.moonlighttalk.server.scheduler.service.SchedulerService;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 배치 수동 실행(<b>개발 전용</b>). 영업일 경계(18시) cron을 기다리지 않고 동작을 확인하기 위한 것으로,
 * {@code app.scheduler.dev-trigger-enabled=true}일 때만 빈으로 등록된다(local 프로필에서만 켠다).
 */
@RestController
@ConditionalOnProperty(name = "app.scheduler.dev-trigger-enabled", havingValue = "true")
public class SchedulerDevController {

    private final SchedulerService schedulerService;

    public SchedulerDevController(SchedulerService schedulerService) {
        this.schedulerService = schedulerService;
    }

    /**
     * 매칭 대화방 일괄 종료 + SYSTEM_CLOSE 방송.
     *
     * <p>Plan_3에서 게이트가 폐지되며 <b>이걸 돌리던 06시 cron이 사라졌다.</b>
     * 방을 언제 닫을지 규칙이 아직 정해지지 않아 기능 자체는 남겨 두고 수동 실행만 가능하게 뒀다
     * (기획 확인 대기 — docs/09 §2-1).
     */
    @PostMapping("/internal/scheduler/close-match-rooms")
    public Map<String, Object> closeMatchRooms(@CurrentUserId String userId) {
        int ended = schedulerService.closeMatchRooms();
        schedulerService.broadcastSystemClose();
        return Map.of("endedRooms", ended);
    }

    /** 지난 영업일 정리. */
    @PostMapping("/internal/scheduler/daily-cleanup")
    public Map<String, Object> dailyCleanup(@CurrentUserId String userId) {
        schedulerService.cleanupPreviousSessions();
        return Map.of("ok", true);
    }

    /** BM 만료 정리(구독·엔티틀먼트·부스트). */
    @PostMapping("/internal/scheduler/expire-benefits")
    public Map<String, Object> expireBenefits(@CurrentUserId String userId) {
        schedulerService.expireBenefits();
        return Map.of("ok", true);
    }

    /** 보관 만료 메시지 삭제(매칭 30일 / 친구 1년). */
    @PostMapping("/internal/scheduler/purge-messages")
    public Map<String, Object> purgeMessages(@CurrentUserId String userId) {
        return Map.of("deleted", schedulerService.purgeExpiredMessages());
    }
}
