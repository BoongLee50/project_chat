package com.moonlighttalk.server.auth.social;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwsHeader;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.LocatorAdapter;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.math.BigInteger;
import java.security.Key;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.RSAPublicKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Sign in with Apple — 앱이 받은 <b>identity token</b>(JWT)을 서버가 직접 검증한다.
 *
 * <ol>
 *   <li>서명: 애플 공개키 목록(JWKS, {@code jwks-url})에서 헤더의 {@code kid}로 키를 찾아 RS256 서명을 확인</li>
 *   <li>{@code iss} = {@code https://appleid.apple.com}</li>
 *   <li>{@code aud} = 우리 클라이언트 ID 중 하나(아이폰 앱은 <b>번들 ID</b>, 웹·안드로이드는 <b>Services ID</b>)</li>
 *   <li>{@code exp} 안 지남(라이브러리가 본다)</li>
 * </ol>
 * {@code sub}가 providerUid다(같은 개발자 팀 안에서 사용자마다 고정).
 *
 * <p>애플은 키를 돌려 쓴다 — 모르는 {@code kid}가 오면 목록을 다시 받는다(1분에 한 번까지).
 */
@Component
@ConditionalOnProperty(name = "app.auth.social.apple.enabled", havingValue = "true")
public class AppleAuthProvider implements SocialAuthProvider {

    static final String ISSUER = "https://appleid.apple.com";
    private static final Duration REFRESH_GAP = Duration.ofMinutes(1);

    private final RestClient restClient = RestClient.create();
    private final SocialAuthProperties.ProviderConfig config;
    private final Map<String, PublicKey> keys = new ConcurrentHashMap<>();
    private volatile Instant lastFetch = Instant.EPOCH;

    public AppleAuthProvider(SocialAuthProperties properties) {
        this.config = properties.getApple();
        if (config.allowedClientIds().isEmpty()) {
            // 켜 놓고 클라이언트 ID를 안 넣으면 어떤 앱의 애플 토큰이든 aud 검사를 못 한다 — 아예 뜨지 않게 한다.
            throw new IllegalStateException("app.auth.social.apple.client-id(APPLE_CLIENT_ID)가 비어 있다");
        }
    }

    @Override
    public SocialUserInfo verify(String providerToken) {
        Claims claims = Jwts.parser()
                .keyLocator(new LocatorAdapter<Key>() {
                    @Override
                    protected Key locate(JwsHeader header) {
                        return keyFor(header.getKeyId());
                    }
                })
                .requireIssuer(ISSUER)
                .build()
                .parseSignedClaims(providerToken)
                .getPayload();

        Set<String> aud = claims.getAudience();
        if (aud == null || aud.stream().noneMatch(config.allowedClientIds()::contains)) {
            throw new IllegalStateException("APPLE 토큰 검증 실패(aud 불일치)");
        }
        String sub = claims.getSubject();
        if (sub == null || sub.isBlank()) {
            throw new IllegalStateException("APPLE 토큰 검증 실패(sub 없음)");
        }
        return new SocialUserInfo(sub);
    }

    private PublicKey keyFor(String kid) {
        PublicKey key = kid == null ? null : keys.get(kid);
        if (key == null && Instant.now().isAfter(lastFetch.plus(REFRESH_GAP))) {
            fetchKeys();
            key = kid == null ? null : keys.get(kid);
        }
        if (key == null) {
            throw new IllegalStateException("APPLE 토큰 검증 실패(모르는 kid " + kid + ")");
        }
        return key;
    }

    private synchronized void fetchKeys() {
        lastFetch = Instant.now();
        Map<?, ?> body = restClient.get().uri(config.getJwksUrl()).retrieve().body(Map.class);
        Object list = body == null ? null : body.get("keys");
        if (!(list instanceof List<?> jwks)) {
            return;
        }
        for (Object o : jwks) {
            if (o instanceof Map<?, ?> jwk && "RSA".equals(jwk.get("kty"))) {
                keys.put(String.valueOf(jwk.get("kid")),
                        rsaKey(String.valueOf(jwk.get("n")), String.valueOf(jwk.get("e"))));
            }
        }
    }

    static PublicKey rsaKey(String n, String e) {
        try {
            Base64.Decoder d = Base64.getUrlDecoder();
            return KeyFactory.getInstance("RSA").generatePublic(
                    new RSAPublicKeySpec(new BigInteger(1, d.decode(n)), new BigInteger(1, d.decode(e))));
        } catch (Exception ex) {
            throw new IllegalStateException("APPLE 공개키를 만들 수 없다", ex);
        }
    }
}
