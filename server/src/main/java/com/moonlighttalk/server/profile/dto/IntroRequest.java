package com.moonlighttalk.server.profile.dto;

/**
 * 자기소개 — <b>최대 300자, 띄어쓰기 포함</b>(기획서 261002 8-1). 옛 "소개 한마디" 50자에서 늘었다(V28).
 *
 * <p>길이는 {@code @Size}(UTF-16 단위)가 아니라 <b>코드포인트</b>로 {@code ProfileService}가 센다 —
 * 이모지도 한 글자이고, DB {@code VARCHAR(300)}과 같은 단위다(신청 한마디와 같은 원칙).
 */
public record IntroRequest(String intro) {
}
