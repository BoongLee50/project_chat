package com.moonlighttalk.server.chat.dto;

import java.time.LocalDateTime;

/** 대화 신청(받은/보낸 목록 공용). status: PENDING|ACCEPTED|REJECTED|BLOCKED */
public record ChatRequestDto(
        String id,
        String fromUserId,
        String toUserId,
        String message,
        String status,
        String partnerNickname,
        Integer partnerAge,
        String partnerCountry,
        String partnerPhotoUrl,
        LocalDateTime createdAt
) {
}
