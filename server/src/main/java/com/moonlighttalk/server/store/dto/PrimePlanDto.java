package com.moonlighttalk.server.store.dto;

import java.util.List;
import java.util.Map;

/** 프라임 플랜(인앱결제) 구성. */
public record PrimePlanDto(
        String productId, String product, int durationDays,
        int luna, List<String> entitlements, Map<String, Integer> boosts
) {
}
