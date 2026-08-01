package com.moonlighttalk.server.garden.entity;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/** 포스트 댓글(기획서 4-2). */
@Getter
@Setter
public class PostComment {
    private String id;
    private String postId;
    private String authorId;
    private String authorNickname;
    private String body;
    private LocalDateTime createdAt;
}
