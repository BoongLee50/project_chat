package com.moonlighttalk.server.profile.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

public record RegionsRequest(@NotNull @Size(max = 2) List<String> codes) {
}
