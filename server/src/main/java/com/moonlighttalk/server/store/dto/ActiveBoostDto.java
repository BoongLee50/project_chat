package com.moonlighttalk.server.store.dto;

import java.time.LocalDateTime;

public record ActiveBoostDto(String kind, LocalDateTime expiresAt) {
}
