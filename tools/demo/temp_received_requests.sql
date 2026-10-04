-- 받은 신청 10칸(2026-10-04) — 임시 유저 40명(`tools/demo/seed_users.py`) 중 10명이 대화 신청.
--
-- 받는 사람은 목 로그인 계정 둘이다 — **같은 10명이 같은 글로** 둘 모두에게 보낸다.
--   [LINE]  mock-dev-line  (Nari)  → id 'temp-q01~10'
--   [KAKAO] mock-dev-kakao (테스)  → id 'temp-k01~10'
-- 계정이 없으면 그 줄만 빠진다. 먼저 `python tools/demo/seed_users.py`로 temp-01~40이 있어야 한다(없으면 FK로 실패).
--
--   mysql -umoonlighttalk -pmoonlighttalk moonlighttalk --default-character-set=utf8mb4 < tools/demo/temp_received_requests.sql
--
-- 섞어 둔 것: 한국어 6 · 일본어 4 / 안 열어 봄 7(N) · 열어 봄 3 / 25자 넘는 글(셀 …) · 100자 꽉 찬 글(팝업)
--            / 시각 5분 전 ~ 10일 전. 🚨 14일이 지나면 배치가 EXPIRED로 내린다 — 다시 돌리면 새 시각으로 들어간다.
-- 다시 돌려도 먼저 비운 뒤 넣는다. 지우기는 CLEANUP 한 줄만.

-- CLEANUP
DELETE FROM chat_requests WHERE id LIKE 'temp-q%' OR id LIKE 'temp-k%';

INSERT INTO chat_requests (id, from_user, to_user, message, status, luna_cost, created_at, viewed_at)
SELECT CONCAT(rc.prefix, m.n), m.from_user, rc.user_id, m.message, 'PENDING', 0,
       NOW() - INTERVAL m.ago_min MINUTE,
       IF(m.viewed_ago_min IS NULL, NULL, NOW() - INTERVAL m.viewed_ago_min MINUTE)
FROM (
    SELECT 'temp-q' AS prefix, id AS user_id FROM users WHERE provider = 'LINE'  AND provider_uid = 'mock-dev-line'
    UNION ALL
    SELECT 'temp-k',           id            FROM users WHERE provider = 'KAKAO' AND provider_uid = 'mock-dev-kakao'
) rc
CROSS JOIN (
              SELECT '01' AS n, 'temp-21' AS from_user, 'はじめまして！プロフィールの写真がとても素敵でした。よかったらお話ししませんか？' AS message, 5 AS ago_min, NULL AS viewed_ago_min
    UNION ALL SELECT '02', 'temp-03', '안녕하세요! 야경 사진 보고 신청했어요 🌙', 40, NULL
    UNION ALL SELECT '03', 'temp-25', '韓国語を勉強しています。日本語も教えられるので、一緒に練習しませんか？よろしくお願いします😊', 120, NULL
    UNION ALL SELECT '04', 'temp-07', '반가워요', 300, NULL
    UNION ALL SELECT '05', 'temp-14', '저도 카페 투어 좋아해요! 서울에 괜찮은 곳 많이 알고 있어서 추천해 드리고 싶어요. 편하게 이야기 나눠요 :)', 540, NULL
    UNION ALL SELECT '06', 'temp-28', 'こんばんは！', 1440, NULL
    UNION ALL SELECT '07', 'temp-10', '프로필 보고 연락드려요. 일본 여행 좋아하신다니 저도 다음 달에 오사카 가는데 이야기 나눠요!', 2880, NULL
    -- 아래 셋은 이미 열어 봄 → N 없음. 08은 100자(코드포인트)를 꽉 채운 글(팝업이 스크롤 없이 버티는지).
    UNION ALL SELECT '08', 'temp-01', '안녕하세요, 민준이라고 해요. 주말마다 사진 찍으러 다니는데 올려 주신 사진 분위기가 정말 좋아서 용기 내서 신청해 봐요. 부담 없이 편하게 이야기 나눠요. 답장 기다릴게요!! 🙂', 5760, 4320
    UNION ALL SELECT '09', 'temp-33', '同じ映画が好きみたいで嬉しいです！おすすめ交換しましょう', 10080, 8640
    UNION ALL SELECT '10', 'temp-05', '좋은 밤이에요. 대화해요', 14400, 12960
) m;
