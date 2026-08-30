package com.moonlighttalk.server.comment.dto;

/**
 * 댓글이 달리는 대상. 규칙(3단계·50자·이미지 1장)이 같아 한 구조를 쓰고, 대상만 이 값으로 가른다.
 *
 * <p>이름에 콘텐츠를 넣지 않는다 — {@code DAILY_ANSWER}는 "달빛 한마디 답변"이지만
 * 그 이름이 바뀌어도 이 상수는 그대로다(docs/12 §6 E).
 */
public enum CommentTarget {
    POST,
    DAILY_ANSWER
}
