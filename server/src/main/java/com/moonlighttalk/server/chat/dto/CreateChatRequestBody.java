package com.moonlighttalk.server.chat.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * 대화 신청 — 한마디는 <b>200자</b>까지(기획 4-3 시안의 `0/200`).
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
