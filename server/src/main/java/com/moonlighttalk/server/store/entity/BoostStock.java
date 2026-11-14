package com.moonlighttalk.server.store.entity;

/** 부스트 보유 매수. (02 §1.7) */
public class BoostStock {

    private String userId;
    private String kind;
    /** PRIME(프라임 구독분) · STORE(상점 구매분). */
    private String source;
    private int quantity;

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

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }
}
