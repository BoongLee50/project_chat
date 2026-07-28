package com.moonlighttalk.server.common.security;

/** 현재 요청의 인증 사용자를 보관(SecurityContextHolder 대체, 05 문서 §11). */
public final class AuthContext {

    private static final ThreadLocal<String> CURRENT_USER_ID = new ThreadLocal<>();

    private AuthContext() {
    }

    public static void set(String userId) {
        CURRENT_USER_ID.set(userId);
    }

    public static String currentUserId() {
        String userId = CURRENT_USER_ID.get();
        if (userId == null) {
            throw new IllegalStateException("인증된 사용자 컨텍스트가 없습니다. @NoAuth 여부를 확인하세요.");
        }
        return userId;
    }

    /** JwtAuthInterceptor#afterCompletion에서 반드시 호출 — 스레드풀 재사용으로 인한 컨텍스트 누수 방지. */
    public static void clear() {
        CURRENT_USER_ID.remove();
    }
}
