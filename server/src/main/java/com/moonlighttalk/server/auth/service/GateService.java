package com.moonlighttalk.server.auth.service;

import com.moonlighttalk.server.auth.dto.GateResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;

/** 서비스 운영시간(Plan_2: 17시 개방 ~ 06시 종료, KST) 판정. 서버 권위 시간 원칙(01 문서 공통 규약). */
@Service
public class GateService {

    private static final ZoneId KST = ZoneId.of("Asia/Seoul");

    private final int openHour;
    private final int closeHour;

    public GateService(
            @Value("${app.gate.open-hour:17}") int openHour,
            @Value("${app.gate.close-hour:6}") int closeHour
    ) {
        this.openHour = openHour;
        this.closeHour = closeHour;
    }

    /** 현재 KST 시각. */
    public ZonedDateTime nowKst() {
        return ZonedDateTime.now(KST);
    }

    /**
     * 영업일(session_date). 하루가 종료시각(06시)에 바뀌므로, 06시 이전은 전날 영업일로 취급한다.
     * 예) 08-02 03:00 → 08-01 / 08-02 07:00 → 08-02. (02 문서 §1.3 posts.session_date)
     */
    public LocalDate currentSessionDate() {
        ZonedDateTime now = nowKst();
        return now.getHour() < closeHour ? now.toLocalDate().minusDays(1) : now.toLocalDate();
    }

    public GateResponse currentGate() {
        ZonedDateTime now = ZonedDateTime.now(KST);
        boolean open = isOpen(now);
        ZonedDateTime nextOpen = nextOpenAt(now);
        return new GateResponse(open, nextOpen.toLocalDateTime());
    }

    public boolean isOpenNow() {
        return isOpen(ZonedDateTime.now(KST));
    }

    private boolean isOpen(ZonedDateTime now) {
        int hour = now.getHour();
        return hour >= openHour || hour < closeHour;
    }

    private ZonedDateTime nextOpenAt(ZonedDateTime now) {
        ZonedDateTime todayOpen = now.withHour(openHour).withMinute(0).withSecond(0).withNano(0);
        return now.isBefore(todayOpen) ? todayOpen : todayOpen.plusDays(1);
    }
}
