package com.moonlighttalk.server.auth.social;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/** app.auth.social.{line|kakao|google|apple}.* 바인딩(05 문서 §9.1). */
@Getter
@Setter
@ConfigurationProperties(prefix = "app.auth.social")
public class SocialAuthProperties {

    private ProviderConfig line = new ProviderConfig();
    private ProviderConfig kakao = new ProviderConfig();
    private ProviderConfig google = new ProviderConfig();
    private ProviderConfig apple = new ProviderConfig();
    /** 개발용 목 로그인(MockAuthProvider) — 로컬 프로필에서만 enabled=true. */
    private ProviderConfig mock = new ProviderConfig();

    @Getter
    @Setter
    public static class ProviderConfig {
        private boolean enabled = false;
        private String clientId;
        /**
         * 받아들일 클라이언트 ID가 **여럿**일 때(구글: 안드로이드·iOS·웹이 각각 다르다 /
         * 애플: 앱 번들 ID와 웹·안드로이드용 Services ID). 쉼표로 적는다. [clientId]와 합쳐서 본다.
         */
        private List<String> clientIds = new ArrayList<>();
        private String clientSecret;
        private String verifyUrl;
        /** 카카오: 토큰이 **우리 앱** 것인지 대조할 앱 ID(카카오 개발자 콘솔의 "앱 ID", 숫자). */
        private String appId;
        /** 애플: 서명 공개키 목록(JWKS) 주소. */
        private String jwksUrl;

        /** [clientId] + [clientIds]에서 빈 값을 뺀 것. */
        public Set<String> allowedClientIds() {
            Set<String> out = new LinkedHashSet<>();
            if (clientId != null && !clientId.isBlank()) {
                out.add(clientId.trim());
            }
            for (String id : clientIds) {
                if (id != null && !id.isBlank()) {
                    out.add(id.trim());
                }
            }
            return out;
        }
    }
}
