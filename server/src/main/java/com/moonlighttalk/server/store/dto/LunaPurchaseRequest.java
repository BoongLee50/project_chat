package com.moonlighttalk.server.store.dto;

import jakarta.validation.constraints.NotBlank;

/** 루나로 개별 상품 구매. productId는 카탈로그의 키. */
public record LunaPurchaseRequest(@NotBlank String productId) {
}
