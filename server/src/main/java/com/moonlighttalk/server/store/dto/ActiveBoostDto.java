package com.moonlighttalk.server.store.dto;

import java.time.LocalDateTime;

/** 켜진 부스트. source = 나간 쪽(PRIME · STORE). */
public record ActiveBoostDto(String kind, String source, LocalDateTime startedAt, LocalDateTime expiresAt) {
}
