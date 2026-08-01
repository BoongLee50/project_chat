package com.moonlighttalk.server.chat.dto;

import java.util.List;

/** @param nextCursor 더 과거 메시지를 읽을 커서(없으면 끝) */
public record MessagePageDto(List<ChatMessageDto> items, String nextCursor) {
}
