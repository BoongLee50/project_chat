package com.moonlighttalk.server.profile.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * 관심사 등록 — <b>최대 3개</b>(기획 7 본문, 확인 2026-09-19).
 *
 * <p>⚠️ 고르는 개수가 3일 뿐 <b>종류는 37종 그대로다.</b> 시안 img21의
 * *"최대 8개"* · `(3/8)` 표기는 낡았지만, 이 화면은 그림이 아니라 <b>코드로 그리는 시트</b>라
 * 새 리소스가 필요하지 않다 — 문구는 ARB가 {@code {max}}로 조립한다.
 *
 * <p>🚨 클라({@code ProfileCatalog.maxInterests})와 <b>두 곳에 같은 숫자가 있다.</b>
 * 한쪽만 고치면 화면은 더 고르게 해 놓고 저장에서 막힌다 — 반드시 함께 바꿀 것.
 */
public record InterestsRequest(@NotNull @Size(max = 3) List<String> codes) {
}
