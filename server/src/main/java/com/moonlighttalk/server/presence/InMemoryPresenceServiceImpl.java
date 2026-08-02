package com.moonlighttalk.server.presence;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
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

    /**
     * 만료된 항목 청소. Redis라면 TTL이 알아서 지우지만 인메모리 맵은 계속 쌓이기만 한다
     * (isOnline이 false를 주더라도 키는 남는다). 05 문서 §스케줄러.
     */
    @Scheduled(fixedDelayString = "${app.scheduler.presence-sweep-ms:300000}")
    public void sweepExpired() {
        Instant threshold = Instant.now().minusSeconds(TTL_SECONDS);
        lastSeen.values().removeIf(seen -> seen.isBefore(threshold));
    }
}
