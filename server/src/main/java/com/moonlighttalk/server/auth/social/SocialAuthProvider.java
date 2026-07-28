package com.moonlighttalk.server.auth.social;

public interface SocialAuthProvider {

    /** 실패 시 RuntimeException(예: IllegalStateException) 발생 */
    SocialUserInfo verify(String providerToken);
}
