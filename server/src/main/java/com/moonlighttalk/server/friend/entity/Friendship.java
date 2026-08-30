package com.moonlighttalk.server.friend.entity;

import java.time.LocalDateTime;

/** friendships 한 행 — 방향은 requester → addressee, 성립 여부는 status. (02 §1.6) */
public class Friendship {

    private String id;
    private String requesterId;
    private String addresseeId;
    private String status;
    private String pairKey;
    /** 친구 신청 한마디(25자, V17). 이 컬럼 이전 요청은 null이다. */
    private String message;
    private LocalDateTime createdAt;
    private LocalDateTime acceptedAt;

    // 조인으로 채우는 상대 정보(요청 목록 표시용)
    private String partnerNickname;
    private Integer partnerBirthYear;
    private String partnerCountry;
    private String partnerPhotoKey;

    /** 나를 기준으로 상대가 누구인지. */
    public String otherOf(String userId) {
        return requesterId.equals(userId) ? addresseeId : requesterId;
    }

    public boolean hasMember(String userId) {
        return requesterId.equals(userId) || addresseeId.equals(userId);
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getRequesterId() {
        return requesterId;
    }

    public void setRequesterId(String requesterId) {
        this.requesterId = requesterId;
    }

    public String getAddresseeId() {
        return addresseeId;
    }

    public void setAddresseeId(String addresseeId) {
        this.addresseeId = addresseeId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getPairKey() {
        return pairKey;
    }

    public void setPairKey(String pairKey) {
        this.pairKey = pairKey;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getAcceptedAt() {
        return acceptedAt;
    }

    public void setAcceptedAt(LocalDateTime acceptedAt) {
        this.acceptedAt = acceptedAt;
    }

    public String getPartnerNickname() {
        return partnerNickname;
    }

    public void setPartnerNickname(String partnerNickname) {
        this.partnerNickname = partnerNickname;
    }

    public Integer getPartnerBirthYear() {
        return partnerBirthYear;
    }

    public void setPartnerBirthYear(Integer partnerBirthYear) {
        this.partnerBirthYear = partnerBirthYear;
    }

    public String getPartnerCountry() {
        return partnerCountry;
    }

    public void setPartnerCountry(String partnerCountry) {
        this.partnerCountry = partnerCountry;
    }

    public String getPartnerPhotoKey() {
        return partnerPhotoKey;
    }

    public void setPartnerPhotoKey(String partnerPhotoKey) {
        this.partnerPhotoKey = partnerPhotoKey;
    }
}
