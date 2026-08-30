package com.moonlighttalk.server.comment.entity;

import com.moonlighttalk.server.comment.dto.CommentTarget;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * 댓글(기획 4-2 / 8-2 / 8-3). <b>3단계까지</b> · 50자 · 이미지 1장.
 *
 * <p>포스트와 달빛 한마디 답변이 <b>같은 규칙</b>을 쓰므로 한 테이블에 담고
 * {@code targetType}으로만 가른다(V14).
 */
@Getter
@Setter
public class Comment {
    private String id;
    private CommentTarget targetType;
    private String targetId;
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
