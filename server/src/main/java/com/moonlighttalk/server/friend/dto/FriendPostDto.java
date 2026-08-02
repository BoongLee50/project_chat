package com.moonlighttalk.server.friend.dto;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 친구 오늘의 포스트 팝업 응답. (01 §1.7 `GET /friends/:id/today-post`)
 *
 * <p>{@code pick}은 지금 부스트를 켜 둔 상태인지(피드의 PICK 마크와 같은 기준).
 */
public record FriendPostDto(
        String userId,
        String nickname,
        Integer age,
        String country,
        boolean pick,
        boolean online,
        List<String> photoUrls,
        String oneLiner,
        int likes,
        int comments,
        LocalDateTime publishedAt
) {
}
