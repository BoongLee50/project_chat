package com.moonlighttalk.server.profile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateProfileRequest(
        @NotBlank String nickname,
        @NotNull Integer birthYear,
        @NotBlank String gender,   // MALE | FEMALE
        @NotBlank String country   // KR | JP
) {
}
