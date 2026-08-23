package com.moonlighttalk.server.chat.dto;

import java.time.LocalDateTime;

/** 대화방 목록 항목. type: MATCH(매칭) | FRIEND(친구 상시) */
public record ChatRoomDto(
        String roomId,
        String type,
        String partnerId,
        String partnerNickname,
        Integer partnerAge,
        String partnerCountry,
        String partnerPhotoUrl,
        String lastMessage,
        String lastMessageType,
        LocalDateTime lastMessageAt,
        int unreadCount
) {
}
