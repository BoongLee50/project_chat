package com.moonlighttalk.server.auth.social;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

import java.util.Map;

/** LINE Login 토큰 검증: POST verify-url (id_token, client_id) → sub 클레임이 providerUid. */
@Component
@ConditionalOnProperty(name = "app.auth.social.line.enabled", havingValue = "true")
public class LineAuthProvider implements SocialAuthProvider {

    private final RestClient restClient = RestClient.create();
    private final SocialAuthProperties.ProviderConfig config;

    public LineAuthProvider(SocialAuthProperties properties) {
        this.config = properties.getLine();
    }

    @Override
    public SocialUserInfo verify(String providerToken) {
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("id_token", providerToken);
        form.add("client_id", config.getClientId());

        Map<?, ?> body = restClient.post()
                .uri(config.getVerifyUrl())
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(form)
                .retrieve()
                .body(Map.class);

        Object sub = body != null ? body.get("sub") : null;
        if (sub == null) {
            throw new IllegalStateException("LINE 토큰 검증 실패");
        }
        return new SocialUserInfo(String.valueOf(sub));
    }
}
