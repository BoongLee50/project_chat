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
    /**
     * 이 시각까지 상대의 받은 신청 목록 최상단(프라임, V22). null이면 우선권 없음.
     *
     * <p>"지금 프라임인가"가 아니라 <b>신청한 그때 샀는가</b>를 남긴다 —
     * 구독이 끝났다고 옛 신청들이 한꺼번에 아래로 떨어지면 안 된다.
     */
    private LocalDateTime priorityUntil;
    // 목록 표시용(조인)
    private String partnerNickname;
    private Integer partnerBirthYear;
    private String partnerCountry;
    private String partnerPhotoKey;
}
