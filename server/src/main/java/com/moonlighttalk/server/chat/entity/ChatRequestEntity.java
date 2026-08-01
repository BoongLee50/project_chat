package com.moonlighttalk.server.chat.entity;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/** 대화 신청(기획서 4-3). 수락 전에는 방이 없고 신청만 존재한다. */
@Getter
@Setter
public class ChatRequestEntity {
    private String id;
    private String fromUser;
    private String toUser;
    private String message;
    private String status;    // PENDING | ACCEPTED | REJECTED | BLOCKED
    private int lunaCost;
    private LocalDateTime createdAt;
    // 목록 표시용(조인)
    private String partnerNickname;
    private Integer partnerBirthYear;
    private String partnerCountry;
    private String partnerPhotoKey;
}
