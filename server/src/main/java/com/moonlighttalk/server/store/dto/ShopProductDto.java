package com.moonlighttalk.server.store.dto;

/**
 * 상점 상품(인앱결제). price는 표시용 기준가(원), discount는 카드의 `○% 할인` 표시(0이면 없음).
 * 기획서 261111 10-2~10-4.
 */
public record ShopProductDto(
        String id, String type, String kind, int price, int quantity, int durationDays, int discount
) {
}
