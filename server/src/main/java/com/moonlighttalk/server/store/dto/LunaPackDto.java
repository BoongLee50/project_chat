package com.moonlighttalk.server.store.dto;

/** 루나 충전 패키지(인앱결제). productId는 스토어 콘솔의 상품 ID와 같아야 한다. */
public record LunaPackDto(String productId, int luna, int bonus, int total) {
}
