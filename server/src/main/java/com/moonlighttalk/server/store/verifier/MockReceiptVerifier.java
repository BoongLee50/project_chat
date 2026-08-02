package com.moonlighttalk.server.store.verifier;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 개발용 영수증 검증기 — 스토어 개발자 계정이 없는 동안 결제 흐름을 시험하기 위한 것.
 * {@code dev-} 로 시작하는 토큰만 통과시킨다. <b>운영에서는 절대 켜지 말 것.</b>
 * (소셜 로그인의 MockAuthProvider와 같은 패턴)
 */
@Component
@ConditionalOnProperty(name = "app.store.mock-purchase-enabled", havingValue = "true")
public class MockReceiptVerifier implements ReceiptVerifier {

    private static final Logger log = LoggerFactory.getLogger(MockReceiptVerifier.class);

    @Override
    public String platform() {
        return "MOCK";
    }

    @Override
    public boolean verify(String productId, String purchaseToken) {
        boolean ok = purchaseToken != null && purchaseToken.startsWith("dev-");
        log.warn("[개발용] 영수증 검증을 건너뜁니다 product={} 통과={}", productId, ok);
        return ok;
    }
}
