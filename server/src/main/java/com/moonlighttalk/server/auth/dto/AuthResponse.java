package com.moonlighttalk.server.auth.dto;

/** status: NEW | PROFILE_REQUIRED | ACTIVE | BANNED (01 문서 §1.1) */
public record AuthResponse(
        String status,
        String accessToken,
        String refreshToken,
        UserSummary user
) {
}
