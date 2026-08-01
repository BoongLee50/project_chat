package com.moonlighttalk.server.post.entity;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/** 포스트 사진. 다운로드 URL은 저장하지 않고 응답 시점에 계산(05 문서 §8). */
@Getter
@Setter
public class PostPhoto {
    private String id;
    private String postId;
    private String userId;
    private String storageKey;
    private int orderIdx;
    private LocalDateTime createdAt;
}
