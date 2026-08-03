package com.moonlighttalk.server.garden.dto;

/// 번역이 일어나는 자리. 무료 쿼터가 자리마다 다르다. (01 §1.4)
public enum TranslateScope {
    /// 달빛가든 댓글 — 하루 **2회** 무료.
    COMMENT,

    /// 채팅 — 하루 **2명** 무료. 한 번 연 상대와는 그날 계속 무료다.
    CHAT,

    /// 프로필 보기 — 항상 무료(쿼터를 세지 않는다).
    PROFILE
}
