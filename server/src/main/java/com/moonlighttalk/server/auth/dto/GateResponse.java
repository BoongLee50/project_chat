package com.moonlighttalk.server.auth.dto;

import java.time.LocalDateTime;

public record GateResponse(boolean open, LocalDateTime nextOpenAt) {
}
