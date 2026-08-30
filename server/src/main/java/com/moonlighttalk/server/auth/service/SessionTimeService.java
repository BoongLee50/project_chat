package com.moonlighttalk.server.auth.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;

/**
 * 서버 시각과 **영업일(session_date)** 판정. 서버 권위 시간 원칙(01 문서 공통 규약).
 *
 * <p>Plan_3에서 야간 운영시간(17~06시)이 폐지되며 이 클래스의 게이트 판정은 사라졌지만,
 * **"하루"의 경계는 남았다** — 사진 삭제 횟수, 가든 열람 조건, 좋아요·댓글 수치,
 * 매력 전환율, 달빛 한마디가 모두 이 경계에서 초기화된다.
 * 그래서 클래스는 남기고 이름만 역할에 맞게 바꿨다(옛 이름은 {@code GateService}).
 *
 * <p>⚠️ **경계 시각을 바꿔 배포할 때는 반드시 그 시각 정각에 배포할 것.**
 * 이미 저장된 행은 옛 기준으로 찍혀 있어, 중간에 바꾸면 한 테이블에 두 기준이 섞인다
 * (docs/12 §6-1).
 */
@Service
public class SessionTimeService {

    private static final ZoneId KST = ZoneId.of("Asia/Seoul");

    /** 영업일이 넘어가는 시각(KST). Plan_3 기준 18시. */
    private final int rolloverHour;

    public SessionTimeService(@Value("${app.session.rollover-hour:18}") int rolloverHour) {
        this.rolloverHour = rolloverHour;
    }

    /** 하루가 바뀌는 시각(KST). 달빛 한마디의 "남은 시간"이 이 값을 쓴다. */
    public int rolloverHour() {
        return rolloverHour;
    }

    /** 현재 KST 시각. */
    public ZonedDateTime nowKst() {
        return ZonedDateTime.now(KST);
    }

    /**
     * 영업일(session_date). 하루가 {@link #rolloverHour}에 바뀌므로 그 이전은 전날로 취급한다.
     *
     * <p>예) 경계가 18시일 때 — 08-29 12:00 → <b>08-28</b> / 08-29 19:00 → <b>08-29</b>.
     */
    public LocalDate currentSessionDate() {
        ZonedDateTime now = nowKst();
        return now.getHour() < rolloverHour ? now.toLocalDate().minusDays(1) : now.toLocalDate();
    }
}
