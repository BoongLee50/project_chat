package com.moonlighttalk.server.store.verifier;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * App Store 영수증 검증. 키가 있어야 동작하므로
 * {@code app.store.apple.enabled=true}일 때만 등록된다.
 *
 * <p>TODO(스토어 계정 발급 후): App Store Server API로 JWS 트랜잭션을 검증할 것.
 */
@Component
@ConditionalOnProperty(name = "app.store.apple.enabled", havingValue = "true")
public class AppleReceiptVerifier implements ReceiptVerifier {

    @Override
    public String platform() {
        return "APPLE";
    }

    @Override
    public boolean verify(String productId, String purchaseToken) {
        throw new UnsupportedOperationException(
                "App Store 영수증 검증 미구현 — 키 발급 후 연동 필요");
    }
}
