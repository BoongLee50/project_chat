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
    /** TEXT / VOICE. VOICE면 body는 비고 audio* 를 쓴다. */
    private String type;
    private String body;
    private String audioKey;
    private Integer audioDurationMs;
    private LocalDateTime createdAt;
    private LocalDateTime readAt;
}
