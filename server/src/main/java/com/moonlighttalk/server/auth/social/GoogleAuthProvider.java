package com.moonlighttalk.server.auth.social;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.Map;
import java.util.Set;

/**
 * Google tokeninfo 엔드포인트: GET verify-url?id_token= → 서명·만료는 구글이 본다.
 * 여기서는 <b>aud가 우리 클라이언트 ID 중 하나</b>이고 <b>iss가 구글</b>인지 본다. sub가 providerUid.
 *
 * <p>🚨 클라이언트 ID가 <b>여럿</b>이다(안드로이드·iOS·웹이 각각 다르다) — `client-ids`에 모두 적는다.
 * 하나만 받으면 다른 플랫폼에서 받은 토큰이 전부 거절된다(2026-11-15 보강).
 */
@Component
@ConditionalOnProperty(name = "app.auth.social.google.enabled", havingValue = "true")
public class GoogleAuthProvider implements SocialAuthProvider {

    private static final Set<String> ISSUERS = Set.of("accounts.google.com", "https://accounts.google.com");

    private final RestClient restClient = RestClient.create();
    private final SocialAuthProperties.ProviderConfig config;

    public GoogleAuthProvider(SocialAuthProperties properties) {
        this.config = properties.getGoogle();
    }

    @Override
    public SocialUserInfo verify(String providerToken) {
        String uri = UriComponentsBuilder.fromHttpUrl(config.getVerifyUrl())
                .queryParam("id_token", providerToken)
                .build()
                .toUriString();

        Map<?, ?> body = restClient.get()
                .uri(uri)
                .retrieve()
                .body(Map.class);

        Object aud = body != null ? body.get("aud") : null;
        if (aud == null || !config.allowedClientIds().contains(String.valueOf(aud))) {
            throw new IllegalStateException("GOOGLE 토큰 검증 실패(client-id 불일치)");
        }
        if (!ISSUERS.contains(String.valueOf(body.get("iss")))) {
            throw new IllegalStateException("GOOGLE 토큰 검증 실패(iss)");
        }
        Object sub = body.get("sub");
        if (sub == null) {
            throw new IllegalStateException("GOOGLE 토큰 검증 실패(sub 없음)");
        }
        return new SocialUserInfo(String.valueOf(sub));
    }
}
