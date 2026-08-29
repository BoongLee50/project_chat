package com.moonlighttalk.server.post.dto;

import java.time.LocalDate;
import java.util.List;

/**
 * 오늘의 포스트 화면 상태(기획서 3-1).
 *
 * <p>Plan_3에서 **운영시간 게이트와 등록 창(1시간)이 폐지**되며 `gateOpen`·`remainingUploadSeconds`·
 * `uploadUnlimited`가 사라졌다. 이제 언제든 등록할 수 있고, 유·무료 차이는 **장수와 교체 횟수**뿐이다.
 *
 * @param photos           표시 순서(<b>최신이 1번 슬롯</b>)
 * @param mainPhotoId      달빛가든에 노출할 대표 사진. 사진이 없으면 null
 * @param maxPhotos        등록 가능한 최대 사진 수(`app.post.max-photos-*`)
 * @param replaceRemaining 남은 사진 교체 횟수(`app.post.replace-limit-*`)
 */
public record MyPostResponse(
        LocalDate sessionDate,
        List<PostPhotoDto> photos,
        String mainPhotoId,
        boolean published,
        int maxPhotos,
        int replaceRemaining
) {
}
