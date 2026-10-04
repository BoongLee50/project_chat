-- 받은 신청 10칸(2026-10-04) — 임시 유저 40명(`tools/demo/seed_users.py`) 중 10명이 Nari에게 대화 신청.
--
-- 받는 사람은 **[LINE] 버튼으로 목 로그인한 계정**(provider_uid = 'mock-dev-line', 닉네임 Nari)이다.
-- 먼저 `python tools/demo/seed_users.py`로 temp-01~40이 있어야 한다(없으면 FK로 실패).
--
--   mysql -umoonlighttalk -pmoonlighttalk moonlighttalk --default-character-set=utf8mb4 < tools/demo/temp_received_requests.sql
--
-- 섞어 둔 것: 한국어 6 · 일본어 4 / 안 열어 봄 7(N) · 열어 봄 3 / 25자 넘는 글(셀 …) · 100자 꽉 찬 글(팝업)
--            / 시각 5분 전 ~ 10일 전. 🚨 14일이 지나면 배치가 EXPIRED로 내린다 — 다시 돌리면 새 시각으로 들어간다.
-- 전부 'temp-q' 접두어다. 다시 돌려도 먼저 비운 뒤 넣는다. 지우기는 CLEANUP 한 줄만.
SET @me = (SELECT id FROM users WHERE provider = 'LINE' AND provider_uid = 'mock-dev-line');

-- CLEANUP
DELETE FROM chat_requests WHERE id LIKE 'temp-q%';

INSERT INTO chat_requests (id, from_user, to_user, message, status, luna_cost, created_at, viewed_at) VALUES
 ('temp-q01', 'temp-21', @me, 'はじめまして！プロフィールの写真がとても素敵でした。よかったらお話ししませんか？', 'PENDING', 0, NOW() - INTERVAL 5 MINUTE, NULL),
 ('temp-q02', 'temp-03', @me, '안녕하세요! 야경 사진 보고 신청했어요 🌙', 'PENDING', 0, NOW() - INTERVAL 40 MINUTE, NULL),
 ('temp-q03', 'temp-25', @me, '韓国語を勉強しています。日本語も教えられるので、一緒に練習しませんか？よろしくお願いします😊', 'PENDING', 0, NOW() - INTERVAL 2 HOUR, NULL),
 ('temp-q04', 'temp-07', @me, '반가워요', 'PENDING', 0, NOW() - INTERVAL 5 HOUR, NULL),
 ('temp-q05', 'temp-14', @me, '저도 카페 투어 좋아해요! 서울에 괜찮은 곳 많이 알고 있어서 추천해 드리고 싶어요. 편하게 이야기 나눠요 :)', 'PENDING', 0, NOW() - INTERVAL 9 HOUR, NULL),
 ('temp-q06', 'temp-28', @me, 'こんばんは！', 'PENDING', 0, NOW() - INTERVAL 1 DAY, NULL),
 ('temp-q07', 'temp-10', @me, '프로필 보고 연락드려요. 일본 여행 좋아하신다니 저도 다음 달에 오사카 가는데 이야기 나눠요!', 'PENDING', 0, NOW() - INTERVAL 2 DAY, NULL),
 -- 아래 셋은 이미 열어 봄 → N 없음. q08은 100자(코드포인트)를 꽉 채운 글(팝업이 스크롤 없이 버티는지).
 ('temp-q08', 'temp-01', @me, '안녕하세요, 민준이라고 해요. 주말마다 사진 찍으러 다니는데 올려 주신 사진 분위기가 정말 좋아서 용기 내서 신청해 봐요. 부담 없이 편하게 이야기 나눠요. 답장 기다릴게요!! 🙂', 'PENDING', 0, NOW() - INTERVAL 4 DAY, NOW() - INTERVAL 3 DAY),
 ('temp-q09', 'temp-33', @me, '同じ映画が好きみたいで嬉しいです！おすすめ交換しましょう', 'PENDING', 0, NOW() - INTERVAL 7 DAY, NOW() - INTERVAL 6 DAY),
 ('temp-q10', 'temp-05', @me, '좋은 밤이에요. 대화해요', 'PENDING', 0, NOW() - INTERVAL 10 DAY, NOW() - INTERVAL 9 DAY);
