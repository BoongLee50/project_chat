package com.moonlighttalk.server.friend.dto;

import java.time.LocalDateTime;

/**
 * 친구 요청 한 건(받은/보낸 공통). partner는 나에게서 본 상대다.
 *
 * @param message 신청자가 남긴 한마디(25자, V17). 이 기능 이전 요청은 null이다 —
 *                그때 화면이 채워 넣던 "친구 요청을 보냈어요"는 <b>상대가 한 말이 아니었다</b>
 */
public record FriendRequestDto(
        String id,
        String requesterId,
        String addresseeId,
        String status,
        String partnerNickname,
        Integer partnerAge,
        String partnerCountry,
        String partnerPhotoUrl,
        String message,
        boolean partnerOnline,
        LocalDateTime createdAt
) {
}
