package com.moonlighttalk.server.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import com.moonlighttalk.server.auth.social.SocialProvider;

public record SocialLoginRequest(
        @NotNull SocialProvider provider,
        @NotBlank String providerToken
) {
}
