package com.moonlighttalk.server.dailyquestion.dto;

/** 목록 정렬(기획 8-1). 기본은 최신순, 인기순은 <b>좋아요 + 댓글 합</b>이다. */
public enum DailyAnswerSort {
    LATEST,
    POPULAR
}
