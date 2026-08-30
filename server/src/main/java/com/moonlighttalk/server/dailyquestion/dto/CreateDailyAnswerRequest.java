package com.moonlighttalk.server.dailyquestion.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * 달빛 한마디 작성(기획 8-3). 최대 <b>100자</b>, 메인 이미지 <b>1장(선택)</b>.
 *
 * <p>길이는 {@code @Size}가 아니라 서비스가 설정값({@code app.daily-question.max-length})으로
 * 판정한다 — 애노테이션에 숫자를 굳히면 설정과 따로 놀고, 기획서가 지정한 문구도 만들 수 없다(④단계).
 */
public record CreateDailyAnswerRequest(
        @NotBlank String body,
        String imageKey
) {
}
