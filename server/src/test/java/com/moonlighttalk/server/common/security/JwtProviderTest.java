package com.moonlighttalk.server.common.security;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtProviderTest {

    private final JwtProvider jwtProvider = new JwtProvider("test-secret-key-please-be-long-enough-0123456789", 60, 30);

    @Test
    void accessToken_발급후_userId를_그대로_복원한다() {
        String userId = "user-123";

        String token = jwtProvider.issueAccessToken(userId);

        assertThat(jwtProvider.parseUserId(token)).isEqualTo(userId);
        assertThat(jwtProvider.isRefreshToken(token)).isFalse();
    }

    @Test
    void refreshToken은_isRefreshToken이_true다() {
        String token = jwtProvider.issueRefreshToken("user-123");

        assertThat(jwtProvider.isRefreshToken(token)).isTrue();
    }

    @Test
    void 위조된_토큰은_파싱에_실패한다() {
        String token = jwtProvider.issueAccessToken("user-123");
        String tampered = token.substring(0, token.length() - 2) + "xx";

        assertThatThrownBy(() -> jwtProvider.parseUserId(tampered))
                .isInstanceOf(RuntimeException.class);
    }
}
