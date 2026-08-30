package com.moonlighttalk.server.presence;

import com.moonlighttalk.server.auth.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 마지막 접속 시각을 <b>눌러서</b> 기록한다(V16).
 *
 * <p>프레즌스는 60초 TTL이라 "지금 있는가"만 안다. 친구 목록의
 * `● 1시간 전 접속`을 그리려면 사라지지 않는 값이 필요해 users에 남긴다.
 *
 * <p>하트비트는 사람마다 30~60초에 한 번 온다. 올 때마다 UPDATE하면 접속자 수만큼
 * 초당 쓰기가 생기므로 <b>사람당 N분에 한 번</b>만 쓴다. 그래서 이 값은 분 단위로
 * 뒤처지는데, 시안이 보여 주는 건 "몇 시간 전"이라 그 정도면 충분하다.
 *
 * <p>눌러 두는 기억은 <b>이 서버 안에만</b> 있다. 서버가 여러 대가 되면 대수만큼
 * 쓰기가 늘지만(대당 N분에 한 번), 그래도 하트비트마다 쓰는 것보다 훨씬 적다.
 */
@Service
public class LastSeenService {

    private final UserMapper userMapper;
    private final long throttleSeconds;

    /** userId → 마지막으로 DB에 쓴 시각. */
    private final Map<String, Instant> written = new ConcurrentHashMap<>();

    public LastSeenService(UserMapper userMapper,
                            @Value("${app.presence.last-seen-throttle-seconds:300}")
                            long throttleSeconds) {
        this.userMapper = userMapper;
        this.throttleSeconds = throttleSeconds;
    }

    public void touch(String userId) {
        if (userId == null) return;

        Instant now = Instant.now();
        Instant previous = written.get(userId);
        if (previous != null && previous.isAfter(now.minusSeconds(throttleSeconds))) {
            return;
        }
        // 같은 순간 두 번 들어와도 UPDATE가 두 번 나갈 뿐 값은 같다 — 잠글 이유가 없다.
        written.put(userId, now);
        userMapper.touchLastSeen(userId, LocalDateTime.now());
    }
}
