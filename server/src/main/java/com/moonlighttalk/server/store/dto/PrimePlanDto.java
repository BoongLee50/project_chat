package com.moonlighttalk.server.store.dto;

import java.util.List;
import java.util.Map;

/** 프라임 플랜(인앱결제) 구성. {@code price}는 표시용 기준가(원) — 실제 청구액은 스토어가 정한다. */
public record PrimePlanDto(
        String productId, String product, int durationDays,
        int luna, List<String> entitlements, Map<String, Integer> boosts, int price
) {
}
