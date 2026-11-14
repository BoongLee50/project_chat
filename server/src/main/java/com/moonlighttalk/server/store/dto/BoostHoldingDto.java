package com.moonlighttalk.server.store.dto;

import java.time.LocalDateTime;

/**
 * 부스트 보유 — 프라임 구독분과 상점 구매분을 따로(기획서 261111 10-2 관리 화면).
 *
 * @param activeSource 지금 켜진 부스트가 나간 쪽(PRIME · STORE · 없으면 null) — 그 칸에 `이용 중`
 */
public record BoostHoldingDto(
        int prime, int store,
        String activeSource, LocalDateTime activeStartedAt, LocalDateTime activeExpiresAt
) {
}
