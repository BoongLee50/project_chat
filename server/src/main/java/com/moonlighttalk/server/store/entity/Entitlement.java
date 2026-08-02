package com.moonlighttalk.server.store.entity;

import java.time.LocalDateTime;

/** 시간제 권리(앨범패스·번역패스·대화무제한·광고제거). 같은 kind는 한 행을 연장한다. (02 §1.7) */
public class Entitlement {

    private String userId;
    private String kind;
    private String source;
    private LocalDateTime startedAt;
    private LocalDateTime expiresAt;

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getKind() {
        return kind;
    }

    public void setKind(String kind) {
        this.kind = kind;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public LocalDateTime getStartedAt() {
        return startedAt;
    }

    public void setStartedAt(LocalDateTime startedAt) {
        this.startedAt = startedAt;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }
}
