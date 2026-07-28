package com.moonlighttalk.server.profile.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

public record InterestsRequest(@NotNull @Size(max = 8) List<String> codes) {
}
