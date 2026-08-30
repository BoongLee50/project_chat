package com.moonlighttalk.server.friend.dto;

import java.time.LocalDateTime;

/**
 * 친구 목록 한 명. {@code roomId}는 수락 시 만들어진 상시 대화방(운영시간 밖에도 유지).
 *
 * @param region     활동 지역 <b>코드</b> 1개. 도시 이름 문구는 클라가 만든다
 * @param lastSeenAt 마지막 접속. {@code online}이 false일 때 `1시간 전 접속`을 그리는 재료다
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
        String region,
        LocalDateTime lastSeenAt,
        LocalDateTime acceptedAt
) {
}
