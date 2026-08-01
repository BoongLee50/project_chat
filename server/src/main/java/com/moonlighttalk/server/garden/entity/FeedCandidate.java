package com.moonlighttalk.server.garden.entity;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/** 피드 후보(오늘 포스트를 공유한 사용자) + 스코어 계산에 필요한 원본 값. */
@Getter
@Setter
public class FeedCandidate {
    private String userId;
    private String postId;
    private String nickname;
    private Integer birthYear;
    private String gender;
    private String country;
    private boolean premium;
    private String oneLiner;
    private LocalDateTime publishedAt;
    /** post_stats 집계(없으면 0). */
    private int exposures;
    private int likes;
    private int requests;
}
