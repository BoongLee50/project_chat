package com.moonlighttalk.server.chat.entity;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/** 대화방 목록 조회용(상대 정보 + 마지막 메시지 + 미확인 수). */
@Getter
@Setter
public class ChatRoomSummary {
    private String roomId;
    private String status;
    private String type;
    private String partnerId;
    private String partnerNickname;
    private Integer partnerBirthYear;
    private String partnerCountry;
    private String partnerPhotoKey;
    private String lastMessage;
    /** 마지막 메시지 종류. 음성이면 목록 미리보기를 문구 대신 "음성 메시지"로 그린다. */
    private String lastMessageType;
    private LocalDateTime lastMessageAt;
    private int unreadCount;
}
