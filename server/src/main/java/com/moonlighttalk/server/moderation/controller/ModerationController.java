package com.moonlighttalk.server.moderation.controller;

import com.moonlighttalk.server.common.security.CurrentUserId;
import com.moonlighttalk.server.moderation.dto.CreateBlockRequest;
import com.moonlighttalk.server.moderation.dto.CreateReportRequest;
import com.moonlighttalk.server.moderation.service.ModerationService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/** 01 문서 §1.7(신고·차단). 기획서 화면 16·17 */
@RestController
public class ModerationController {

    private final ModerationService moderationService;

    public ModerationController(ModerationService moderationService) {
        this.moderationService = moderationService;
    }

    @PostMapping("/reports")
    public void report(@CurrentUserId String userId,
                        @Valid @RequestBody CreateReportRequest request) {
        moderationService.report(userId, request.targetUserId(),
                request.reason(), request.detail());
    }

    @PostMapping("/blocks")
    public void block(@CurrentUserId String userId,
                       @Valid @RequestBody CreateBlockRequest request) {
        moderationService.block(userId, request.targetUserId());
    }
}
