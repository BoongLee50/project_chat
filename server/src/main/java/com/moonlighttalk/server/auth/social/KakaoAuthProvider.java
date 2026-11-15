package com.moonlighttalk.server.auth.social;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.Map;

/**
 * 카카오 토큰 정보 API: GET verify-url(`/v1/user/access_token_info`) + Authorization: Bearer {token}
 * → `{ id, expires_in, app_id }`. id가 providerUid.
 *
 * <p>🚨 <b>`app_id`가 우리 앱인지 반드시 본다</b>(2026-11-15 보강). 예전에는 `/v2/user/me`로 사용자만 조회해서
 * <b>다른 앱에서 발급된 카카오 토큰으로도 로그인이 됐다</b> — 남의 앱이 받아 둔 토큰으로 그 사람 행세를 할 수 있는 구멍이다.
 * 만료된 토큰은 카카오가 401로 돌려준다(AuthService가 로그인 실패로 바꾼다).
 */
@Component
@ConditionalOnProperty(name = "app.auth.social.kakao.enabled", havingValue = "true")
public class KakaoAuthProvider implements SocialAuthProvider {

    private final RestClient restClient = RestClient.create();
    private final SocialAuthProperties.ProviderConfig config;

    public KakaoAuthProvider(SocialAuthProperties properties) {
        this.config = properties.getKakao();
        if (config.getAppId() == null || config.getAppId().isBlank()) {
            // 켜 놓고 앱 ID를 안 넣으면 아무 앱의 토큰이나 통과한다 — 아예 뜨지 않게 한다.
            throw new IllegalStateException("app.auth.social.kakao.app-id(KAKAO_APP_ID)가 비어 있다");
        }
    }

    @Override
    public SocialUserInfo verify(String providerToken) {
        Map<?, ?> body = restClient.get()
                .uri(config.getVerifyUrl())
                .header("Authorization", "Bearer " + providerToken)
                .retrieve()
                .body(Map.class);

        Object appId = body != null ? body.get("app_id") : null;
        if (appId == null || !config.getAppId().trim().equals(String.valueOf(appId))) {
            throw new IllegalStateException("KAKAO 토큰 검증 실패(다른 앱의 토큰)");
        }
        Object id = body.get("id");
        if (id == null) {
            throw new IllegalStateException("KAKAO 토큰 검증 실패");
        }
        return new SocialUserInfo(String.valueOf(id));
    }
}
