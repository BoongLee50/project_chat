package com.moonlighttalk.server.auth.social;

import org.springframework.stereotype.Component;

import java.util.EnumMap;
import java.util.Map;
import java.util.Optional;

/** enabled=true인 provider만 빈으로 존재 → 여기 등록됨(05 문서 §9.1). */
@Component
public class SocialAuthProviderRegistry {

    private final Map<SocialProvider, SocialAuthProvider> providers = new EnumMap<>(SocialProvider.class);

    public SocialAuthProviderRegistry(
            Optional<LineAuthProvider> line,
            Optional<KakaoAuthProvider> kakao,
            Optional<GoogleAuthProvider> google
    ) {
        line.ifPresent(p -> providers.put(SocialProvider.LINE, p));
        kakao.ifPresent(p -> providers.put(SocialProvider.KAKAO, p));
        google.ifPresent(p -> providers.put(SocialProvider.GOOGLE, p));
    }

    public Optional<SocialAuthProvider> find(SocialProvider provider) {
        return Optional.ofNullable(providers.get(provider));
    }
}
