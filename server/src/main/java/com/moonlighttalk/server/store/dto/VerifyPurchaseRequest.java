package com.moonlighttalk.server.store.dto;

import jakarta.validation.constraints.NotBlank;

/** 인앱결제 영수증 검증 요청. (01 §1.8 결제 흐름 ②) */
public record VerifyPurchaseRequest(
        @NotBlank String platform,      // GOOGLE | APPLE
        @NotBlank String productId,
        @NotBlank String purchaseToken
) {
}
