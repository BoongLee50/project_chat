package com.moonlighttalk.server.store.dto;

/** 루나로 사는 상품. price 단위는 루나. discount는 상점 카드의 `○% 할인` 표시(0이면 없음). */
public record LunaProductDto(
        String id, String type, String kind, int price, int quantity, int durationDays, int discount
) {
}
