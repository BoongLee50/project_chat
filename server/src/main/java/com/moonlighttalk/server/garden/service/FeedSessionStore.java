package com.moonlighttalk.server.garden.service;

import com.moonlighttalk.server.garden.config.GardenProperties;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * "가든 진입 시 <b>1회 산정</b>, 그 세션 동안 순서 유지"(기획서 4-1)를 담는 곳.
 *
 * <p><b>이것이 [07 §5-2 피드 부채]의 답이다.</b> 지금까지는 요청마다 후보를 다시 뽑고
 * 다시 섞었다. 오프셋 페이징이라 2페이지를 받을 때는 <b>1페이지와 다른 순서</b> 위에서 잘라 와
 * 본 카드가 또 나오거나 누군가 건너뛰어졌다. 순서를 한 번 정해 두면 그 문제가 사라진다.
 *
 * <p><b>왜 메모리인가</b> — 피드 순서는 몇 분이면 의미가 없어지는 값이라 DB에 남길 이유가 없다.
 * 서버가 재시작되면 다음 진입에서 새로 산정될 뿐이고, 사용자에게는 "가든에 다시 들어간 것"과 같다.
 * 프레즌스와 같은 성격의 상태이며(그쪽도 인메모리·Redis 선택),
 * <b>인스턴스를 늘릴 때 함께 Redis로 옮긴다</b>(07 §5 부채와 같은 줄기).
 */
@Component
public class FeedSessionStore {

    /** 한 번 산정한 노출 순서. */
    public record Snapshot(
            /** 순서가 고정된 대상 userId 목록. */
            List<String> userIds,
            /** 이 순서를 만들 때 쓴 필터. 필터가 바뀌면 다시 산정해야 한다. */
            String filterKey,
            Instant createdAt
    ) {}

    private final Map<String, Snapshot> snapshots = new ConcurrentHashMap<>();
    private final GardenProperties properties;

    public FeedSessionStore(GardenProperties properties) {
        this.properties = properties;
    }

    /**
     * 살아 있는 순서가 있으면 돌려준다. 없거나 <b>필터가 바뀌었으면</b> null —
     * 호출부가 새로 산정한다.
     */
    public Snapshot get(String userId, String filterKey) {
        Snapshot snapshot = snapshots.get(userId);
        if (snapshot == null) {
            return null;
        }
        if (!snapshot.filterKey().equals(filterKey)) {
            return null;
        }
        Duration ttl = Duration.ofMinutes(properties.getSessionTtlMinutes());
        if (Duration.between(snapshot.createdAt(), Instant.now()).compareTo(ttl) > 0) {
            snapshots.remove(userId, snapshot);
            return null;
        }
        return snapshot;
    }

    public Snapshot put(String userId, String filterKey, List<String> userIds) {
        Snapshot snapshot = new Snapshot(List.copyOf(userIds), filterKey, Instant.now());
        snapshots.put(userId, snapshot);
        return snapshot;
    }

    /**
     * 순서를 버린다. 다음 조회에서 새로 산정된다.
     *
     * <p>"풀을 다 보면 처음부터 다시"(기획서 4-1)가 여기로 들어온다 — 끝까지 넘긴 사람에게
     * 옛 순서를 그대로 다시 주면 방금 본 순서를 또 보게 된다.
     */
    public void clear(String userId) {
        snapshots.remove(userId);
    }

    /** 만료된 순서를 치운다(스케줄러가 주기적으로 부른다). */
    public int evictExpired() {
        Duration ttl = Duration.ofMinutes(properties.getSessionTtlMinutes());
        Instant now = Instant.now();
        int before = snapshots.size();
        snapshots.values().removeIf(
                s -> Duration.between(s.createdAt(), now).compareTo(ttl) > 0);
        return before - snapshots.size();
    }
}
