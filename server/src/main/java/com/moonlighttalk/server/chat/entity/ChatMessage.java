package com.moonlighttalk.server.chat.entity;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class ChatMessage {
    private String id;
    private String roomId;
    private String senderId;
    private String body;
    private LocalDateTime createdAt;
    private LocalDateTime readAt;
}
