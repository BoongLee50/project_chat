package com.moonlighttalk.server.auth.service;

import com.moonlighttalk.server.auth.dto.GateResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.ZoneId;
import java.time.ZonedDateTime;

/** 서비스 운영시간(18~05시 KST) 판정. 서버 권위 시간 원칙(01 문서 공통 규약). */
@Service
public class GateService {

    private static final ZoneId KST = ZoneId.of("Asia/Seoul");

    private final int openHour;
    private final int closeHour;

    public GateService(
            @Value("${app.gate.open-hour:18}") int openHour,
            @Value("${app.gate.close-hour:5}") int closeHour
    ) {
        this.openHour = openHour;
        this.closeHour = closeHour;
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
