package com.moonlighttalk.server.friend.dto;

import java.time.LocalDateTime;

/**
 * 친구 목록 한 명. {@code roomId}는 수락 시 만들어진 상시 대화방(운영시간 밖에도 유지).
 *
 * @param region      활동 지역 <b>코드</b> 1개. 도시 이름 문구는 클라가 만든다
 * @param lastSeenAt  마지막 접속. {@code online}이 false일 때 `1시간 전 접속`을 그리는 재료다
 * @param pinned      <b>내가</b> 목록 상단에 고정했는가(V27 — 핀마크)
 * @param newlyAdded  친구가 된 지 {@code app.friend.new-days}(7)일이 안 됐는가(기획 7-1 "신규 등록", N마크).
 *                    판정을 서버가 한다 — 기기 시계가 틀려도 N이 달라지지 않게
 * @param pinnedAt    고정한 시각. 고정끼리는 "최신순"(늦게 고정한 것이 위) — 서버 정렬의 기준이다
 */
public record FriendDto(
        String friendshipId,
        String userId,
        String nickname,
        Integer age,
        String gender,
        String country,
        String intro,
        String photoUrl,
        String roomId,
        boolean online,
        String region,
        LocalDateTime lastSeenAt,
        LocalDateTime acceptedAt,
        boolean pinned,
        boolean newlyAdded,
        LocalDateTime pinnedAt
) {
}
