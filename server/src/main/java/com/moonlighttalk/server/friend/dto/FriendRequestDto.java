package com.moonlighttalk.server.friend.dto;

import java.time.LocalDateTime;

/** 친구 요청 한 건(받은/보낸 공통). partner는 나에게서 본 상대다. */
public record FriendRequestDto(
        String id,
        String requesterId,
        String addresseeId,
        String status,
        String partnerNickname,
        Integer partnerAge,
        String partnerCountry,
        String partnerPhotoUrl,
        LocalDateTime createdAt
) {
}
