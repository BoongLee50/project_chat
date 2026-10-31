package com.moonlighttalk.server.store.dto;

/**
 * 루나 충전 패키지(인앱결제). productId는 스토어 콘솔의 상품 ID와 같아야 한다.
 * price는 표시용 기준가(원), badge는 카드 리본(POPULAR · BEST · null).
 */
public record LunaPackDto(String productId, int luna, int bonus, int total, int price, String badge) {
}
