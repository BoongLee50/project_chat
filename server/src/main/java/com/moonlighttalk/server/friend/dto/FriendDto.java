package com.moonlighttalk.server.friend.dto;

import java.time.LocalDateTime;

/**
 * 친구 목록 한 명. {@code roomId}는 수락 시 만들어진 상시 대화방(운영시간 밖에도 유지).
 */
public record FriendDto(
        String friendshipId,
        String userId,
        String nickname,
        Integer age,
        String gender,
        String country,
        String intro,
        String photoUrl,
        String roomId,
        boolean online,
        LocalDateTime acceptedAt
) {
}
