package com.moonlighttalk.server.profile.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * 활동 지역 — <b>최대 1곳</b>(기획서 261002 8-1). 2곳에서 줄었다(V28이 넘치는 행을 지웠다).
 *
 * <p>🚨 클라({@code ProfileCatalog.maxRegions})와 같은 숫자다 — 함께 바꿀 것.
 */
public record RegionsRequest(@NotNull @Size(max = 1) List<String> codes) {
}
