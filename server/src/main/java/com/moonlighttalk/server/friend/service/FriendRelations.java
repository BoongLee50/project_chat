package com.moonlighttalk.server.friend.service;

import com.moonlighttalk.server.friend.entity.Friendship;

/**
 * 나와 상대의 친구 관계를 <b>한 낱말</b>로 정리한다.
 *
 * <p>대화방 목록의 [친구]/[친구 신청]/[신청 대기] 버튼과 [포스트 정보]의 ⋮ [친구 해제]가
 * 같은 판정을 쓴다. 두 곳에 따로 적어 두면 한쪽만 고쳐진 채 남는다.
 *
 * <p>{@code friendships}에는 REJECTED가 없다 — 거절하면 <b>행을 지운다</b>(02 §1.6).
 * 그래서 "아무 사이도 아님"과 "거절당함"은 구분되지 않고, 구분할 이유도 없다.
 */
public final class FriendRelations {

    /** 아무 사이도 아니다 → [친구 신청] */
    public static final String NONE = "NONE";
    /** 내가 보냈고 답을 기다린다 → [신청 대기] */
    public static final String REQUESTED = "REQUESTED";
    /** 상대가 보냈고 내가 답할 차례다 → [친구 수락] */
    public static final String INCOMING = "INCOMING";
    /** 이미 친구다 → [친구] */
    public static final String FRIEND = "FRIEND";

    private FriendRelations() {
    }

    public static String of(Friendship friendship, String userId) {
        if (friendship == null) return NONE;
        if ("ACCEPTED".equals(friendship.getStatus())) return FRIEND;
        return userId.equals(friendship.getRequesterId()) ? REQUESTED : INCOMING;
    }

    /** 방향과 무관하게 같은 값이 나오도록 정렬해 잇는다. */
    public static String pairKey(String a, String b) {
        return a.compareTo(b) <= 0 ? a + "_" + b : b + "_" + a;
    }
}
