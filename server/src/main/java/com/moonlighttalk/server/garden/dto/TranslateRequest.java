package com.moonlighttalk.server.garden.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/// 번역 요청. (01 §1.4)
///
/// [scope]에 따라 무료 쿼터가 다르다 — 댓글은 **창 5회 호출**, 채팅은 **대화방 5개**,
/// 프로필 보기는 항상 무료(V20).
///
/// ⚠️ 채팅 쿼터는 **평생 5개**다 — 방이 닫혀도 자리가 돌아오지 않는다(기획 답변 2026-09-06).
public record TranslateRequest(
        @NotBlank String text,
        String targetLang,
        @NotNull TranslateScope scope,
        /// `scope=CHAT`일 때 **대화방 id**.
        ///
        /// ⚠️ 이름이 `targetId`인 건 V7 시절 "하루 2명"이라 상대 userId를 받던 잔재다.
        /// V20에서 세는 단위가 **방**으로 바뀌었다.
        String targetId
) {
}
