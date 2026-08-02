package com.moonlighttalk.server.friend.entity;

import java.time.LocalDateTime;

/** 친구의 오늘 포스트 한 건 + 표시에 필요한 상대 정보. (기획서 화면 19) */
public class FriendPost {

    private String postId;
    private String userId;
    private String nickname;
    private Integer birthYear;
    private String country;
    private String oneLiner;
    private LocalDateTime publishedAt;
    private int likes;

    public String getPostId() {
        return postId;
    }

    public void setPostId(String postId) {
        this.postId = postId;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public Integer getBirthYear() {
        return birthYear;
    }

    public void setBirthYear(Integer birthYear) {
        this.birthYear = birthYear;
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }

    public String getOneLiner() {
        return oneLiner;
    }

    public void setOneLiner(String oneLiner) {
        this.oneLiner = oneLiner;
    }

    public LocalDateTime getPublishedAt() {
        return publishedAt;
    }

    public void setPublishedAt(LocalDateTime publishedAt) {
        this.publishedAt = publishedAt;
    }

    public int getLikes() {
        return likes;
    }

    public void setLikes(int likes) {
        this.likes = likes;
    }
}
