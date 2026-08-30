package com.moonlighttalk.server.store.dto;

import java.util.List;

/**
 * 상품 카탈로그. 가격·구성은 설정에서 온다(현금 가격은 스토어 SDK의 현지 가격).
 *
 * @param maxPhotosFree 무료 사용자의 포스트 사진 수
 * @param maxPhotosPass 앨범 패스·프라임의 포스트 사진 수
 *
 * <p>🚨 사진 장수가 <b>카탈로그에 있는 이유</b>: BM 화면의 혜택 문구가
 * *"포스트 사진 최대 9장 등록"*, *"기본 2장에서 최대 9장까지"* 라고 말한다(기획 화면 26·29).
 * 서버가 주지 않으면 그 숫자는 결국 앱 코드나 번역 파일에 굳는다 —
 * 설정(`app.post.max-photos-*`)이 바뀌는 순간 화면이 거짓말을 하게 된다.
 */
public record ProductCatalogDto(
        List<LunaProductDto> lunaProducts,
        List<LunaPackDto> lunaPacks,
        List<PrimePlanDto> primePlans,
        int maxPhotosFree,
        int maxPhotosPass
) {
}
