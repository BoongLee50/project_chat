package com.moonlighttalk.server.garden.dto;

import java.time.LocalDateTime;

public record CommentDto(
        String id,
        String authorId,
        String authorNickname,
        String body,
        LocalDateTime createdAt
) {
}
