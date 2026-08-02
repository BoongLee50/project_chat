package com.moonlighttalk.server.moderation.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateBlockRequest(@NotBlank String targetUserId) {
}
