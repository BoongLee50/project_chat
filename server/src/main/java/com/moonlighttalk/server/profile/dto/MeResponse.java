package com.moonlighttalk.server.profile.dto;

import java.util.List;

public record MeResponse(
        String id,
        String nickname,
        Integer birthYear,
        String gender,
        String country,
        boolean premium,
        String photoUrl,
        String intro,
        List<String> interests,
        List<String> regions
) {
}
