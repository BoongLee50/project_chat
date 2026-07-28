package com.moonlighttalk.server.profile.dto;

import jakarta.validation.constraints.Size;

public record IntroRequest(@Size(max = 50) String intro) {
}
