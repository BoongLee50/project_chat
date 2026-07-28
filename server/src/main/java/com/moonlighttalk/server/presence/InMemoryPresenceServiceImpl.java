package com.moonlighttalk.server.presence;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@ConditionalOnProperty(name = "app.redis.enabled", havingValue = "false", matchIfMissing = true)
public class InMemoryPresenceServiceImpl implements PresenceService {

    private static final long TTL_SECONDS = 60;

    private final Map<String, Instant> lastSeen = new ConcurrentHashMap<>();

    @Override
    public void heartbeat(String userId) {
        lastSeen.put(userId, Instant.now());
    }

    @Override
    public boolean isOnline(String userId) {
        Instant seen = lastSeen.get(userId);
        return seen != null && seen.isAfter(Instant.now().minusSeconds(TTL_SECONDS));
    }
}
