-- 받은 친구 신청 10칸(2026-10-04) — 임시 유저 40명(`tools/demo/seed_users.py`) 중 10명이 친구 신청.
--
-- 그날 DB에 직접 넣고 파일로 남기지 않았던 것을 **다른 기기에서도 똑같이** 만들 수 있게 옮겨 적었다.
-- 받는 사람은 목 로그인 계정 둘 — **같은 10명이 같은 글로** 둘 모두에게 보낸다(대화 신청 `temp_received_requests.sql`과 짝).
--   [LINE]  mock-dev-line  (Nari)
--   [KAKAO] mock-dev-kakao (테스 — 플립4 폰에서 만든 계정)
-- 계정이 없으면 그 줄만 빠진다. 먼저 `python tools/demo/seed_users.py`로 temp-01~40이 있어야 한다(없으면 FK로 실패).
--
--   mysql -umoonlighttalk -pmoonlighttalk moonlighttalk --default-character-set=utf8mb4 < tools/demo/temp_friend_requests.sql
--
-- 섞어 둔 것: 한국어 5 · 일본어 5 / 안 열어 봄 8(N) · 열어 봄 2 / 시각 2시간 반 전 ~ 2일 전.
-- 🚨 14일이 지나면 배치가 친구 신청을 **지운다**(만료 = 행 삭제) — 다시 돌리면 새 시각으로 들어간다.
--
-- 📌 다시 돌리면 **대기 중(PENDING)인 것만** 비우고 다시 넣는다. 폰에서 수락해 친구가 된 사람·고정은 그대로 두고,
--    이미 친구인 짝은 건너뛴다(pair_key UNIQUE + INSERT IGNORE) — 테스트하며 만든 상태를 날리지 않으려고.
--    (2026-10-04 테스 계정은 폰에서 7명을 수락하고 둘을 고정했다 — 그건 이 파일이 만든 것이 아니다.)

-- CLEANUP (대기 중인 temp 친구 신청만)
DELETE FROM friendships WHERE status = 'PENDING' AND requester_id LIKE 'temp-%';

INSERT IGNORE INTO friendships (id, requester_id, addressee_id, status, pair_key, message, created_at, viewed_at)
SELECT UUID(), m.from_user, rc.user_id, 'PENDING',
       CONCAT(LEAST(rc.user_id, m.from_user), '_', GREATEST(rc.user_id, m.from_user)),
       m.message,
       NOW() - INTERVAL m.ago_min MINUTE,
       IF(m.viewed_ago_min IS NULL, NULL, NOW() - INTERVAL m.viewed_ago_min MINUTE)
FROM (
    SELECT id AS user_id FROM users WHERE provider = 'LINE'  AND provider_uid = 'mock-dev-line'
    UNION ALL
    SELECT id            FROM users WHERE provider = 'KAKAO' AND provider_uid = 'mock-dev-kakao'
) rc
CROSS JOIN (
              SELECT 'temp-02' AS from_user, '대화 너무 즐거웠어요! 친구로 지내요 :)'              AS message, 160  AS ago_min, NULL AS viewed_ago_min
    UNION ALL SELECT 'temp-22', 'お話しできて楽しかったです。友達になりませんか？',                 180,  NULL
    UNION ALL SELECT 'temp-04', '사진 취향이 비슷해서 반가웠어요. 친구 해요!',                       210,  120
    UNION ALL SELECT 'temp-26', '韓国のこと、もっと教えてください！',                                250,  NULL
    UNION ALL SELECT 'temp-06', '다음에 또 이야기 나눠요~',                                          310,  NULL
    UNION ALL SELECT 'temp-31', 'これからもよろしくお願いします！',                                  400,  NULL
    UNION ALL SELECT 'temp-11', '영화 이야기 더 하고 싶어요. 친구 신청 받아 주세요!',                560,  300
    UNION ALL SELECT 'temp-32', '一緒に日本語と韓国語の練習しましょう',                              880,  NULL
    UNION ALL SELECT 'temp-12', '편하게 연락하는 친구가 되고 싶어요',                                1600, NULL
    UNION ALL SELECT 'temp-35', 'また話しましょうね。友達申請します！',                              3040, NULL
) m;
