package com.moonlighttalk.server.chat.dto;

import java.time.LocalDateTime;

/**
 * 채팅 메시지.
 *
 * <p>{@code type}이 {@code VOICE}면 {@code body}는 비고 {@code audioUrl}·{@code audioDurationMs}를 쓴다.
 * 길이를 함께 내려주는 이유는 클라가 파일을 받기 전에도 말풍선 크기와 시간을 그릴 수 있어야 해서다.
 */
public record ChatMessageDto(
        String id,
        String roomId,
        String senderId,
        String type,
        String body,
        String audioUrl,
        Integer audioDurationMs,
        LocalDateTime createdAt,
        boolean read
) {
}
