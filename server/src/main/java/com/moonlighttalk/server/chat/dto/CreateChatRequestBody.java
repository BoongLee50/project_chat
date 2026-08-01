package com.moonlighttalk.server.chat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** 대화 신청 — 메시지는 100자까지(기획서 4-3). */
public record CreateChatRequestBody(
        @NotBlank String targetUserId,
        @NotBlank @Size(max = 100) String message
) {
}
