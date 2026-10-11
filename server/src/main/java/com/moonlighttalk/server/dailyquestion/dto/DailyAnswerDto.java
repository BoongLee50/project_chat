package com.moonlighttalk.server.dailyquestion.dto;

import java.time.LocalDateTime;

/**
 * 달빛 한마디 한 건.
 *
 * @param photoUrl  얼굴 사진(없으면 null) — [답글 목록] 셀의 동그라미(기획서 261011 9-2)
 * @param online    지금 접속 중인가 — 셀의 `● ON`(시안 둘째 칸)
 * @param imageUrl  메인 이미지(없으면 null)
 * @param likedByMe 내가 좋아요를 눌렀는가 — 눌린 상태를 보여주고 두 번 세지 않기 위해
 */
public record DailyAnswerDto(
        String id,
        String userId,
        String nickname,
        Integer age,
        String country,
        String photoUrl,
        boolean online,
        String body,
        String imageUrl,
        int likes,
        int comments,
        boolean likedByMe,
        boolean mine,
        LocalDateTime createdAt
) {
}
