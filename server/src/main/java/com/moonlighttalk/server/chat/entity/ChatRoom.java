package com.moonlighttalk.server.chat.entity;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/** 1:1 대화방. MATCH=매칭 대화, FRIEND=친구 상시 대화방(게이트·자동삭제 예외). */
@Getter
@Setter
public class ChatRoom {
    private String id;
    private String userA;
    private String userB;
    private String status;   // ACTIVE | ENDED
    private String type;     // MATCH | FRIEND
    private String requestId;
    private LocalDateTime endedAt;
    private LocalDateTime createdAt;

    public boolean hasMember(String userId) {
        return userA.equals(userId) || userB.equals(userId);
    }

    public String otherOf(String userId) {
        return userA.equals(userId) ? userB : userA;
    }
}
