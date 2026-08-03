package com.moonlighttalk.server.garden.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/// 번역 요청. (01 §1.4)
///
/// [scope]에 따라 무료 쿼터가 다르다 — 댓글은 하루 2회, 채팅은 하루 2명,
/// 프로필 보기는 항상 무료. 채팅은 "누구와"를 세야 하므로 [targetId]가 필요하다.
public record TranslateRequest(
        @NotBlank String text,
        String targetLang,
        @NotNull TranslateScope scope,
        /// 채팅 상대 userId. `scope=CHAT`일 때만 쓰인다.
        String targetId
) {
}
