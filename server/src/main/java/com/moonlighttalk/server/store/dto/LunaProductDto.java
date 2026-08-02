package com.moonlighttalk.server.store.dto;

/** 루나로 사는 상품. price 단위는 루나. */
public record LunaProductDto(
        String id, String type, String kind, int price, int quantity, int durationDays
) {
}
