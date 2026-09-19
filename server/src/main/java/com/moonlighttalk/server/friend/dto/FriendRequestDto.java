package com.moonlighttalk.server.friend.dto;

import java.time.LocalDateTime;

/**
 * 친구 요청 한 건(받은/보낸 공통). partner는 나에게서 본 상대다.
 *
 * @param message 신청자가 남긴 한마디(100자, V26). 이 기능 이전 요청은 null이다 —
 *                그때 화면이 채워 넣던 "친구 요청을 보냈어요"는 <b>상대가 한 말이 아니었다</b>
 * @param viewed  받는 사람이 이 신청을 열어 봤는가(V27). false면 셀에 `N`이 붙는다 —
 *                대화방 받은 신청과 같은 뜻이다(기획 7-2 "대화 목록창과 동일")
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
        LocalDateTime createdAt,
        boolean viewed
) {
}
