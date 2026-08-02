package com.moonlighttalk.server.scheduler.controller;

import com.moonlighttalk.server.common.security.CurrentUserId;
import com.moonlighttalk.server.scheduler.service.SchedulerService;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 배치 수동 실행(<b>개발 전용</b>). 06시 cron을 기다리지 않고 동작을 확인하기 위한 것으로,
 * {@code app.scheduler.dev-trigger-enabled=true}일 때만 빈으로 등록된다(local 프로필에서만 켠다).
 */
@RestController
@ConditionalOnProperty(name = "app.scheduler.dev-trigger-enabled", havingValue = "true")
public class SchedulerDevController {

    private final SchedulerService schedulerService;

    public SchedulerDevController(SchedulerService schedulerService) {
        this.schedulerService = schedulerService;
    }

    /** 06시 종료 처리(매칭 대화방 종료 + SYSTEM_CLOSE). */
    @PostMapping("/internal/scheduler/gate-close")
    public Map<String, Object> gateClose(@CurrentUserId String userId) {
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

    /** 보관 만료 메시지 삭제(매칭 30일 / 친구 1년). */
    @PostMapping("/internal/scheduler/purge-messages")
    public Map<String, Object> purgeMessages(@CurrentUserId String userId) {
        return Map.of("deleted", schedulerService.purgeExpiredMessages());
    }
}
