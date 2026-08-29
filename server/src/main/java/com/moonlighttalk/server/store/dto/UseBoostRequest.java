package com.moonlighttalk.server.store.dto;

import jakarta.validation.constraints.NotBlank;

/** kind: POST_BOOST (Plan_3에서 스포트라이트 폐지) */
public record UseBoostRequest(@NotBlank String kind) {
}
