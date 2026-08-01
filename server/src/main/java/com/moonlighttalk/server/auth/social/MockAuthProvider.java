package com.moonlighttalk.server.auth.social;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 개발용 목(mock) 소셜 인증 — 실제 소셜 키 없이 로그인 흐름을 테스트하기 위한 구현.
 *
 * <p>{@code app.auth.social.mock.enabled=true}(로컬 프로필 전용)일 때만 빈으로 등록되며,
 * 실제 provider(LINE/KAKAO/GOOGLE)가 비활성인 자리를 대신 채운다
 * ({@link SocialAuthProviderRegistry}). 운영 프로필에서는 절대 켜지 않는다.
 *
 * <p>providerToken을 그대로 식별자로 사용하므로, 토큰 문자열을 바꾸면 다른 테스트 계정이 된다.
 * 예: {@code "dev-1"} → providerUid {@code "mock-dev-1"}.
 */
@Component
@ConditionalOnProperty(name = "app.auth.social.mock.enabled", havingValue = "true")
public class MockAuthProvider implements SocialAuthProvider {

    @Override
    public SocialUserInfo verify(String providerToken) {
        if (providerToken == null || providerToken.isBlank()) {
            throw new IllegalStateException("mock providerToken이 비어 있습니다.");
        }
        return new SocialUserInfo("mock-" + providerToken.trim());
    }
}
