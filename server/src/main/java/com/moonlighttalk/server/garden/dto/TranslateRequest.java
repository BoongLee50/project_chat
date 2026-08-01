package com.moonlighttalk.server.garden.dto;

import jakarta.validation.constraints.NotBlank;

public record TranslateRequest(@NotBlank String text, String targetLang) {
}
