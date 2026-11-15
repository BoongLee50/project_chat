package com.moonlighttalk.server.store.entity;

import java.time.LocalDateTime;

/** 프라임 멤버십 구독. (02 §1.7) */
public class Subscription {

    private String id;
    private String userId;
    private String product;
    private String status;
    private LocalDateTime startedAt;
    private LocalDateTime expiresAt;
    /** 프라임 부스트를 마지막으로 준 때(30일마다 10개씩 더한다). */
    private LocalDateTime boostGrantedAt;
    private Boolean autoRenew;
    private String storeTxn;
    private LocalDateTime createdAt;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getProduct() {
        return product;
    }

    public void setProduct(String product) {
        this.product = product;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
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

    public Boolean getAutoRenew() {
        return autoRenew;
    }

    public void setAutoRenew(Boolean autoRenew) {
        this.autoRenew = autoRenew;
    }

    public String getStoreTxn() {
        return storeTxn;
    }

    public void setStoreTxn(String storeTxn) {
        this.storeTxn = storeTxn;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getBoostGrantedAt() {
        return boostGrantedAt;
    }

    public void setBoostGrantedAt(LocalDateTime boostGrantedAt) {
        this.boostGrantedAt = boostGrantedAt;
    }
}
