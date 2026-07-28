package com.moonlighttalk.server.presence;

/** Redis 선택 구성 예시(05 문서 §2). app.redis.enabled 값에 따라 구현체가 스위칭된다. */
public interface PresenceService {

    void heartbeat(String userId);

    boolean isOnline(String userId);
}
