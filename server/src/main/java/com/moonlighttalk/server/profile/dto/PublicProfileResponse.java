package com.moonlighttalk.server.profile.dto;

import java.util.List;

/** GET /users/:id/profile — 상대 프로필(출생년도 등 민감정보 제외). */
public record PublicProfileResponse(
        String id,
        String nickname,
        String gender,
        String country,
        boolean premium,
        String photoUrl,
        String intro,
        List<String> interests,
        List<String> regions
) {
}
