package com.moonlighttalk.server.store.dto;

import java.time.LocalDateTime;

/**
 * 패스(포스트 앨범·자동 번역) 보유 — 프라임 구독분과 상점 구매분을 따로(기획서 261111 10-3·10-4 관리 화면).
 *
 * <p>상점 구매분은 프라임이 끝난 뒤부터 흐르므로(사용자 2026-11-14) {@code storeStartedAt}이 미래일 수 있다.
 * 둘 다 없으면 null.
 */
public record PassHoldingDto(
        LocalDateTime primeStartedAt, LocalDateTime primeExpiresAt,
        LocalDateTime storeStartedAt, LocalDateTime storeExpiresAt
) {
}
