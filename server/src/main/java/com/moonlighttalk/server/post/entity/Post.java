package com.moonlighttalk.server.post.entity;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

/** 하루치 포스트(영업일 단위). 02 문서 §1.3 */
@Getter
@Setter
public class Post {
    private String id;
    private String userId;
    private LocalDate sessionDate;
    private LocalDateTime publishedAt;
    /** 당일 사진 교체(삭제) 횟수. */
    private int replaceCount;
    /**
     * 달빛가든 대표 사진({@code post_photos.id}). FK가 없어 떠 있을 수 있으므로
     * <b>읽는 쪽이 실재 여부를 확인</b>한다(V11 주석 참고).
     */
    private String mainPhotoId;
}
