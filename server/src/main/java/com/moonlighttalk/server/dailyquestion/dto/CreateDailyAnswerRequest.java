package com.moonlighttalk.server.dailyquestion.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * [내 한마디 등록](기획서 261011 9-1). 최대 <b>200자</b>(띄어쓰기 포함, 코드포인트), 사진 <b>1장(선택)</b>.
 *
 * <p>길이는 {@code @Size}가 아니라 서비스가 설정값({@code app.daily-question.max-length})으로
 * 판정한다 — 애노테이션에 숫자를 굳히면 설정과 따로 놀고, 기획서가 지정한 문구도 만들 수 없다(④단계).
 */
public record CreateDailyAnswerRequest(
        @NotBlank String body,
        String imageKey
) {
}
