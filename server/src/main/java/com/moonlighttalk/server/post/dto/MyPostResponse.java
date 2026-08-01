package com.moonlighttalk.server.post.dto;

import java.time.LocalDate;
import java.util.List;

/**
 * 오늘의 포스트 화면 상태(01 문서 §1.3, 기획서 3-1).
 *
 * @param remainingUploadSeconds 남은 등록 가능 시간(초). 무제한(프라임/앨범패스)이면 null → 클라는 "PASS" 표시
 * @param uploadUnlimited        시간 제한 없음 여부
 * @param maxPhotos              등록 가능한 최대 사진 수(일반 2 / 패스 8)
 * @param replaceRemaining       남은 사진 교체 횟수(일반 2 / 패스 20)
 */
public record MyPostResponse(
        LocalDate sessionDate,
        boolean gateOpen,
        List<PostPhotoDto> photos,
        String oneLiner,
        boolean published,
        Long remainingUploadSeconds,
        boolean uploadUnlimited,
        int maxPhotos,
        int replaceRemaining
) {
}
