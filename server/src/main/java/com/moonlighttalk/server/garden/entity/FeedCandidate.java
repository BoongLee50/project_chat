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
    private String intro;

    /** 활동 지역 코드 1개 — 카드에 "한국, 서울"로 보여 준다(기획 §2-5). */
    private String region;
    private LocalDateTime publishedAt;
    /** 사진이 마지막으로 바뀐 시각(V8). Recency는 공유 시각과 이 값 중 <b>나중</b>을 본다. */
    private LocalDateTime contentUpdatedAt;
    /** 이 포스트의 사진 수. 열람 제한으로 잘라 보낼 때 "원래 몇 장인지" 알려주는 데 쓴다. */
    private int photoCount;
    /** post_stats 집계(없으면 0). */
    private int exposures;
    private int likes;
    private int comments;
    private int requests;
    /** 내가 이미 좋아요를 눌렀는가 — 하루 한 번이라 눌린 상태를 화면이 보여줘야 한다. */
    private boolean likedByMe;
}
