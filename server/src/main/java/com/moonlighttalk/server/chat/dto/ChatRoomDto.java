package com.moonlighttalk.server.chat.dto;

import java.time.LocalDateTime;

/**
 * 대화방 목록 항목. type: MATCH(매칭) | FRIEND(친구 상시)
 *
 * @param partnerOnline  행에 🟢 접속 표시를 그린다(기획 6-1)
 * @param friendRelation 행 오른쪽 [친구]/[친구 신청]/[신청 대기] 버튼 —
 *                       {@code FriendRelations}의 낱말이다
 */
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
        int unreadCount,
        boolean partnerOnline,
        String friendRelation
) {
}
