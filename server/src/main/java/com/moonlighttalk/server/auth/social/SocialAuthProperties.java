package com.moonlighttalk.server.auth.social;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

/** app.auth.social.{line|kakao|google}.* 바인딩(05 문서 §9.1). */
@Getter
@Setter
@ConfigurationProperties(prefix = "app.auth.social")
public class SocialAuthProperties {

    private ProviderConfig line = new ProviderConfig();
    private ProviderConfig kakao = new ProviderConfig();
    private ProviderConfig google = new ProviderConfig();
    /** 개발용 목 로그인(MockAuthProvider) — 로컬 프로필에서만 enabled=true. */
    private ProviderConfig mock = new ProviderConfig();

    @Getter
    @Setter
    public static class ProviderConfig {
        private boolean enabled = false;
        private String clientId;
        private String clientSecret;
        private String verifyUrl;
    }
}
