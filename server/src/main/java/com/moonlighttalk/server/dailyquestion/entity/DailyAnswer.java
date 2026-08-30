package com.moonlighttalk.server.dailyquestion.entity;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

/** 오늘의 질문에 대한 답(기획 8-3). 하루에 한 사람 한 글(DB 유니크로 막는다). */
@Getter
@Setter
public class DailyAnswer {
    private String id;
    private String questionId;
    private String userId;
    private LocalDate sessionDate;
    private String body;
    private String imageKey;
    private LocalDateTime createdAt;

    // ── 조회 시 함께 채우는 값 ──
    private String nickname;
    private Integer birthYear;
    private String country;
    private int likes;
    private boolean likedByMe;
}
