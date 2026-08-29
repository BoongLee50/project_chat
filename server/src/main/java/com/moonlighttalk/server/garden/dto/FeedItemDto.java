package com.moonlighttalk.server.garden.dto;

import java.util.List;

/**
 * 달빛가든 피드 카드 1건.
 *
 * @param score 정렬에 쓰인 Post Score(디버깅/검증용, 클라 표시는 선택)
 * @param pick  부스팅(PICK) 마크 표시 대상 여부
 */
public record FeedItemDto(
        String userId,
        String nickname,
        Integer age,
        String country,
        boolean pick,
        boolean online,
        String intro,
        List<String> photoUrls,
        List<String> interests,
        int likes,
        int comments,
        int score
) {
}
