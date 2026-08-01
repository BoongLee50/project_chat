package com.moonlighttalk.server.post.dto;

import jakarta.validation.constraints.NotBlank;

public record RegisterPhotoRequest(@NotBlank String storageKey) {
}
