package com.moonlighttalk.server.chat.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * 대화 신청 — 한마디는 <b>150자</b>까지(기획 4-3 <b>본문</b>, 확인 2026-09-19).
 *
 * <p>⚠️ 시안 img09의 입력칸은 `0/200`이지만 <b>본문이 맞다.</b> V19가 시안만 보고
 * 100 → 200으로 넓혔던 것을 V25에서 되돌렸다.
 *
 * <p>길이를 {@code @Size}로 막지 않는 건 일반 VALIDATION_FAILED가 나가면
 * 화면이 "몇 자까지인지"를 말해 줄 수 없기 때문이다. 서비스가 설정값과 견주고
 * 한도를 {@code field}에 실어 돌려보낸다(②단계에서 세운 방식).
 */
public record CreateChatRequestBody(
        @NotBlank String targetUserId,
        @NotBlank String message
) {
}
