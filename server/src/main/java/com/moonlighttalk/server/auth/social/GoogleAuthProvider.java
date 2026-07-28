package com.moonlighttalk.server.auth.social;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.Map;

/** Google tokeninfo 엔드포인트: GET verify-url?id_token= → aud가 client-id와 일치해야 하고, sub가 providerUid. */
@Component
@ConditionalOnProperty(name = "app.auth.social.google.enabled", havingValue = "true")
public class GoogleAuthProvider implements SocialAuthProvider {

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
        if (aud == null || !aud.equals(config.getClientId())) {
            throw new IllegalStateException("GOOGLE 토큰 검증 실패(client-id 불일치)");
        }
        Object sub = body.get("sub");
        return new SocialUserInfo(String.valueOf(sub));
    }
}
