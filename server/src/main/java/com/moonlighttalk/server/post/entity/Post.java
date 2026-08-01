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
    private String oneLiner;
    private LocalDateTime publishedAt;
    /** 등록 가능 창 시작(일반 사용자 1시간 계산 기준). */
    private LocalDateTime windowStartedAt;
    /** 당일 사진 교체(삭제) 횟수. */
    private int replaceCount;
}
