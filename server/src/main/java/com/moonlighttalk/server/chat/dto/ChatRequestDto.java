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
        LocalDateTime createdAt,
        boolean partnerOnline,
        /// 받는 사람이 이 신청을 열어 봤는가(V26). false면 셀에 미확인 표시(`N`)가 붙는다.
        boolean viewed
) {
}
