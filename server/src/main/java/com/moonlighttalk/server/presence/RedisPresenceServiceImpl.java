package com.moonlighttalk.server.presence;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Service
@ConditionalOnProperty(name = "app.redis.enabled", havingValue = "true")
public class RedisPresenceServiceImpl implements PresenceService {

    private static final Duration TTL = Duration.ofSeconds(60);
    private static final String KEY_PREFIX = "presence:";

    private final StringRedisTemplate redisTemplate;

    public RedisPresenceServiceImpl(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    public void heartbeat(String userId) {
        redisTemplate.opsForValue().set(KEY_PREFIX + userId, "1", TTL);
    }

    @Override
    public boolean isOnline(String userId) {
        return Boolean.TRUE.equals(redisTemplate.hasKey(KEY_PREFIX + userId));
    }
}
