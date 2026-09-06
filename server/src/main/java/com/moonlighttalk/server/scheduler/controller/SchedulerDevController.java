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

    /** 지난 영업일 정리. */
    @PostMapping("/internal/scheduler/daily-cleanup")
    public Map<String, Object> dailyCleanup(@CurrentUserId String userId) {
        schedulerService.cleanupPreviousSessions();
        return Map.of("ok", true);
    }

    /** 답하지 않은 신청 만료(대화·친구). 14일을 기다리지 않고 동작을 보려는 것이다. */
    @PostMapping("/internal/scheduler/expire-requests")
    public Map<String, Object> expireRequests(@CurrentUserId String userId) {
        SchedulerService.ExpiredRequests r = schedulerService.expireStaleRequests();
        return Map.of("chatRequests", r.chatRequests(), "friendRequests", r.friendRequests());
    }

    /** BM 만료 정리(구독·엔티틀먼트·부스트). */
    @PostMapping("/internal/scheduler/expire-benefits")
    public Map<String, Object> expireBenefits(@CurrentUserId String userId) {
        schedulerService.expireBenefits();
        return Map.of("ok", true);
    }

    /**
     * 보관 만료 메시지 삭제 → 비어 버린 대화방 종료.
     *
     * <p>실제 잡과 <b>같은 순서</b>로 부른다 — 메시지를 먼저 지워야 방이 비었는지 알 수 있다.
     * 따로 부를 수 있게 두면 순서를 틀린 채 확인하게 된다.
     */
    @PostMapping("/internal/scheduler/purge-messages")
    public Map<String, Object> purgeMessages(@CurrentUserId String userId) {
        int deleted = schedulerService.purgeExpiredMessages();
        int closed = schedulerService.closeEmptyRooms();
        return Map.of("deleted", deleted, "closedRooms", closed);
    }
}
