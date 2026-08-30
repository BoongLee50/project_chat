package com.moonlighttalk.server.garden.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 무료 번역 쿼터(기획 4-2 · 5장 · 8-3).
 *
 * <p>🚨 <b>자리마다 세는 단위가 다르다.</b> 값만 보고 옮기면 안 된다.
 * <ul>
 *   <li><b>댓글창</b> — *"댓글창 5회 <b>호출</b>까지 무료"*. 번역 건수가 아니라
 *       <b>창을 여는 횟수</b>다. 창 하나를 열면 그 안의 댓글은 몇 개든 번역된다.</li>
 *   <li><b>대화방</b> — *"[대화방]은 5개까지 무료 번역. <b>대화방 삭제 전까지</b> 계속"*.
 *       하루가 아니라 <b>동시에 열어 둘 수 있는 방의 수</b>다.</li>
 *   <li><b>프로필 보기</b> — 쿼터를 세지 않는다.</li>
 * </ul>
 *
 * <p>⑦단계 전에는 둘 다 "하루 2회"였다 — 값도 단위도 기획서와 달랐다.
 */
@Component
@ConfigurationProperties(prefix = "app.translate")
public class TranslateProperties {

    /** 공급자 이름. {@code none}이면 원문을 그대로 돌려준다(아직 붙이지 않았다). */
    private String provider = "none";

    /** 무료로 열 수 있는 <b>댓글창 호출</b> 횟수(영업일 기준). */
    private int freeCommentOpens = 5;

    /** 무료로 <b>동시에</b> 열어 둘 수 있는 대화방 수. 방이 끝나면 자리가 빈다. */
    private int freeChatRooms = 5;

    public String getProvider() {
        return provider;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }

    public int getFreeCommentOpens() {
        return freeCommentOpens;
    }

    public void setFreeCommentOpens(int freeCommentOpens) {
        this.freeCommentOpens = freeCommentOpens;
    }

    public int getFreeChatRooms() {
        return freeChatRooms;
    }

    public void setFreeChatRooms(int freeChatRooms) {
        this.freeChatRooms = freeChatRooms;
    }
}
