package com.moonlighttalk.server.store.verifier;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Google Play 영수증 검증. 서비스 계정 키가 있어야 동작하므로
 * {@code app.store.google.enabled=true}일 때만 등록된다.
 *
 * <p>TODO(스토어 계정 발급 후): Google Play Developer API
 * {@code purchases.products.get} / {@code purchases.subscriptionsv2.get}으로 상태를 확인하고,
 * 소비형 상품은 {@code purchases.products.acknowledge}까지 처리할 것.
 */
@Component
@ConditionalOnProperty(name = "app.store.google.enabled", havingValue = "true")
public class GoogleReceiptVerifier implements ReceiptVerifier {

    @Override
    public String platform() {
        return "GOOGLE";
    }

    @Override
    public boolean verify(String productId, String purchaseToken) {
        throw new UnsupportedOperationException(
                "Google Play 영수증 검증 미구현 — 서비스 계정 키 발급 후 연동 필요");
    }
}
