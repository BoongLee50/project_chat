package com.moonlighttalk.server.common.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;

/** REST 인터셉터와 WebSocket AUTH 패킷 처리에서 공용으로 사용(05 문서 §11). */
@Component
public class JwtProvider {

    private static final String CLAIM_TYPE = "type";
    private static final String TYPE_ACCESS = "access";
    private static final String TYPE_REFRESH = "refresh";

    private final SecretKey key;
    private final Duration accessTokenTtl;
    private final Duration refreshTokenTtl;

    public JwtProvider(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.access-token-ttl-minutes:60}") long accessTokenTtlMinutes,
            @Value("${app.jwt.refresh-token-ttl-days:30}") long refreshTokenTtlDays
    ) {
        if (secret == null || secret.isBlank()) {
            throw new IllegalStateException("app.jwt.secret 설정이 비어 있습니다.");
        }
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessTokenTtl = Duration.ofMinutes(accessTokenTtlMinutes);
        this.refreshTokenTtl = Duration.ofDays(refreshTokenTtlDays);
    }

    public String issueAccessToken(String userId) {
        return issueToken(userId, TYPE_ACCESS, accessTokenTtl);
    }

    public String issueRefreshToken(String userId) {
        return issueToken(userId, TYPE_REFRESH, refreshTokenTtl);
    }

    private String issueToken(String userId, String type, Duration ttl) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userId)
                .claim(CLAIM_TYPE, type)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(ttl)))
                .signWith(key)
                .compact();
    }

    /** 서명·만료 검증 후 subject(userId) 반환. 실패 시 JwtException 계열 RuntimeException 발생. */
    public String parseUserId(String token) {
        return parseClaims(token).getSubject();
    }

    public boolean isRefreshToken(String token) {
        return TYPE_REFRESH.equals(parseClaims(token).get(CLAIM_TYPE, String.class));
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
