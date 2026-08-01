package com.moonlighttalk.server.garden.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** 댓글 작성(최대 25자, 대댓글 없음 — 기획서 4-2). */
public record CreateCommentRequest(@NotBlank @Size(max = 25) String body) {
}
