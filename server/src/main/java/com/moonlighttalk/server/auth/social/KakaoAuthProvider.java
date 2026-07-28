package com.moonlighttalk.server.auth.social;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.Map;

/** 카카오 사용자 정보 조회 API: GET verify-url + Authorization: Bearer {token} → id 필드가 providerUid. */
@Component
@ConditionalOnProperty(name = "app.auth.social.kakao.enabled", havingValue = "true")
public class KakaoAuthProvider implements SocialAuthProvider {

    private final RestClient restClient = RestClient.create();
    private final SocialAuthProperties.ProviderConfig config;

    public KakaoAuthProvider(SocialAuthProperties properties) {
        this.config = properties.getKakao();
    }

    @Override
    public SocialUserInfo verify(String providerToken) {
        Map<?, ?> body = restClient.get()
                .uri(config.getVerifyUrl())
                .header("Authorization", "Bearer " + providerToken)
                .retrieve()
                .body(Map.class);

        Object id = body != null ? body.get("id") : null;
        if (id == null) {
            throw new IllegalStateException("KAKAO 토큰 검증 실패");
        }
        return new SocialUserInfo(String.valueOf(id));
    }
}
