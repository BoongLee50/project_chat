package com.moonlighttalk.server.friend.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * 친구 신청. {@code message}는 신청과 함께 보내는 한마디(선택, 25자 — 기획 5-1).
 *
 * <p>길이는 여기서 애너테이션으로 자르지 않고 <b>서비스가 설정값과 견준다</b>.
 * 애너테이션으로 막으면 일반 VALIDATION_FAILED가 나가서, 화면이 "몇 자까지인지"를
 * 말해 줄 수 없다(함정 — 댓글 50자에서 같은 일을 겪었다).
 */
public record CreateFriendRequestBody(@NotBlank String targetUserId, String message) {
}
