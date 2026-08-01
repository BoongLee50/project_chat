package com.moonlighttalk.server.chat.dto;

import java.time.LocalDateTime;

public record ChatMessageDto(
        String id,
        String roomId,
        String senderId,
        String body,
        LocalDateTime createdAt,
        boolean read
) {
}
