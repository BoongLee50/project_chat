package com.moonlighttalk.server.profile.dto;

import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

/**
 * 프로필 생성(온보딩 완료).
 *
 * <p>나이는 <b>{@code birthDate}(연·월·일, V33)</b>로 받는다 — 온보딩 STEP 2가 날짜를 받는다(그래픽 소스 2026-11-21).
 * 옛 앱이 보내는 {@code birthYear}만 있는 요청도 받는다(둘 다 없으면 400). 날짜가 오면 해는 거기서 뽑는다.
 */
public record CreateProfileRequest(
        @NotBlank String nickname,
        Integer birthYear,
        LocalDate birthDate,
        @NotBlank String gender,   // MALE | FEMALE
        @NotBlank String country   // KR | JP
) {
}
