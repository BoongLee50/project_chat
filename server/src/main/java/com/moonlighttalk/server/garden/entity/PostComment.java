package com.moonlighttalk.server.garden.entity;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * 포스트 댓글(기획서 4-2). <b>3단계까지</b> · 50자 · 이미지 1장.
 *
 * <p>달빛 한마디(8-2·8-3)의 댓글도 규칙이 같아 ⑤단계에서 이 구조를 재사용한다 —
 * 그래서 이름에 콘텐츠를 넣지 않았다(docs/12 §6 E).
 */
@Getter
@Setter
public class PostComment {
    private String id;
    private String postId;
    private String authorId;
    private String authorNickname;
    private String body;
    /** 부모 댓글 id. 1단계면 null. */
    private String parentId;
    /** 1=댓글, 2=대댓글, 3=대대댓글. */
    private int depth;
    /** 첨부 이미지의 스토리지 키(선택). */
    private String imageKey;
    private LocalDateTime createdAt;
}
