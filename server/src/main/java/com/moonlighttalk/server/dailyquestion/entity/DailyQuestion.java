package com.moonlighttalk.server.dailyquestion.entity;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

/**
 * 오늘의 질문(기획 8-1). 영업일마다 하나이고 <b>KST 18시에 새 질문</b>으로 바뀐다.
 *
 * <p>본문을 두 언어로 들고 있는 이유 — 질문은 화면 문구가 아니라 <b>콘텐츠</b>라 ARB에 넣을 수 없는데,
 * 한·일 동시 오픈이라 한 벌만 두면 한쪽이 읽지 못한다.
 */
@Getter
@Setter
public class DailyQuestion {
    private String id;
    private LocalDate sessionDate;
    private String bodyKo;
    private String bodyJa;

    /** 기기 언어에 맞는 본문. 아는 언어가 아니면 한국어(원문)로 돌려준다. */
    public String bodyFor(String lang) {
        return "ja".equalsIgnoreCase(lang) ? bodyJa : bodyKo;
    }
}
