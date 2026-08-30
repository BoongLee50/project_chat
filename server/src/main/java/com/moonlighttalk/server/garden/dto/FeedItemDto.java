package com.moonlighttalk.server.garden.dto;

import java.util.List;

/**
 * 달빛가든 피드 카드 1건.
 *
 * @param pick        부스팅(PICK) 마크 표시 대상 여부. <b>Plan_3에서 점수 가점은 아니다</b> —
 *                    부스트는 별도 풀로 섞이므로 이 값은 표시용이다
 * @param photoUrls   실제로 볼 수 있는 사진. <b>열람 제한이 걸리면 메인 1장만 담긴다</b>
 * @param photoLocked 나머지 사진이 잠겨 있는가(오늘 내 포스트를 공유하지 않은 무료 사용자)
 * @param totalPhotos 원래 몇 장인지. 잠겨 있어도 "더 있다"를 보여줘야 안내가 말이 된다
 * @param likedByMe   내가 이미 좋아요를 눌렀는가. <b>하루 한 번</b>이라 눌린 상태를 보여준다
 * @param region      활동 지역 <b>코드</b> 1개. 문구("한국, 서울")는 클라가 만든다
 * @param score       정렬에 쓰인 Post Score(디버깅/검증용)
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
        boolean photoLocked,
        int totalPhotos,
        List<String> interests,
        int likes,
        int comments,
        boolean likedByMe,
        String region,
        int score
) {
}
