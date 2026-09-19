package com.moonlighttalk.server.profile.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * 관심사 등록 — <b>최대 3개</b>(기획 7 본문, 확인 2026-09-19).
 *
 * <p>⚠️ 고르는 개수가 3일 뿐 <b>종류는 37종 그대로다.</b> 목록을 줄이는 것이 아니다.
 *
 * <p>🚨 <b>관심사 화면의 버튼·아이콘은 전부 이미지다</b>(기획 2026-09-19).
 * 지금은 37종 중 <b>`영화` 한 장만</b> 와 있고 나머지는 코드가 그리고 있다 —
 * 리소스가 오면 갈아 끼운다. 자세한 것은 docs/08 §0-2.
 *
 * <p>🚨 클라({@code ProfileCatalog.maxInterests})와 <b>두 곳에 같은 숫자가 있다.</b>
 * 한쪽만 고치면 화면은 더 고르게 해 놓고 저장에서 막힌다 — 반드시 함께 바꿀 것.
 */
public record InterestsRequest(@NotNull @Size(max = 3) List<String> codes) {
}
