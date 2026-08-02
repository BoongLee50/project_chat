package com.moonlighttalk.server.store.dto;

import jakarta.validation.constraints.NotBlank;

/** kind: POST_BOOST | SPOTLIGHT_BOOST */
public record UseBoostRequest(@NotBlank String kind) {
}
