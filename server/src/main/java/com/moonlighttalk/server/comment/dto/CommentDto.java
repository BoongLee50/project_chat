package com.moonlighttalk.server.comment.dto;

import java.time.LocalDateTime;

/**
 * 댓글 1건. 목록은 <b>트리 순서로 평탄화</b>해서 내려간다 —
 * 부모 바로 뒤에 그 답글이 오므로 클라는 {@code depth}만큼 들여쓰면 된다.
 *
 * @param depth    1=댓글, 2=대댓글, 3=대대댓글
 * @param imageUrl 첨부 이미지(없으면 null). 서버가 응답 시점에 계산한다
 * @param authorCountry  작성자 국적 — 이름 옆 국기(기획 4-2 시안)
 * @param authorPhotoUrl 작성자 <b>얼굴 사진</b>(없으면 null) — 줄 왼쪽 동그라미
 */
public record CommentDto(
        String id,
        String parentId,
        int depth,
        String authorId,
        String authorNickname,
        String authorCountry,
        String authorPhotoUrl,
        String body,
        String imageUrl,
        LocalDateTime createdAt
) {
}
