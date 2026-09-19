-- 친구 화면 UI 확인용 데모 데이터(2026-09-19). 전부 'demo-f' 접두어다.
--
-- 받는 사람은 **[LINE] 버튼으로 목 로그인한 계정**(provider_uid = 'mock-dev-line')이다.
-- 그 계정으로 한 번 로그인·프로필 생성을 마친 뒤에 돌릴 것 — 없으면 @me가 NULL이라 아무것도 안 들어간다.
--
--   mysql -umoonlighttalk -pmoonlighttalk moonlighttalk --default-character-set=utf8mb4 < tools/demo/demo_friend.sql
--
-- 들어가는 것 — [친구 목록] 5칸(서버가 정한 순서대로 보여야 한다):
--   1. 서아(KR·서울)  — 내가 **상단 고정** → 핀. 친구 된 지 20일. 관심사 MOVIE(그림)·MUSIC·CAFE(자리 칩)
--   2. みお(JP·도쿄)  — **어제 친구가 됨** → N, 탭 숫자 1. 일본어 자기소개(번역 확인용)
--   3. 지우(KR·부산)  — 3시간 전 접속
--   4. はるか(JP·오사카) — 2일 전 접속
--   5. 채원(KR, 사진 없음) — 접속 기록 없음
--   ⚠️ 접속 표시(ON)는 소켓이 붙어야 켜지므로 데모로는 못 본다(온라인은 최근 접속보다 위다).
-- [받은 신청] 2칸 — 다인(안 열어 봄 → N · 탭 숫자 1) · なな(열어 봄, 일본어 한마디 — 번역 확인용).
--
-- 사진은 `server/server/uploads/seed/p1~p3`를 쓴다(저장소에 없으면 사진 칸만 빈다).
-- 지우기: 아래 CLEANUP 블록만 돌리면 된다(다시 돌려도 먼저 비운 뒤 넣는다). 친구 관계는 사용자 삭제로 함께 지워진다.
SET @me = (SELECT id FROM users WHERE provider = 'LINE' AND provider_uid = 'mock-dev-line');

-- CLEANUP (먼저 한 번 비운다)
-- 수락해 보면 친구 대화방이 생긴다 — 방부터 지워야 사용자를 지울 수 있다(chat_rooms FK).
DELETE FROM chat_messages   WHERE room_id IN (SELECT id FROM chat_rooms WHERE user_a LIKE 'demo-f%' OR user_b LIKE 'demo-f%');
DELETE FROM translate_rooms WHERE room_id IN (SELECT id FROM chat_rooms WHERE user_a LIKE 'demo-f%' OR user_b LIKE 'demo-f%');
DELETE FROM chat_rooms      WHERE user_a LIKE 'demo-f%' OR user_b LIKE 'demo-f%';
DELETE FROM friendships   WHERE requester_id LIKE 'demo-f%' OR addressee_id LIKE 'demo-f%';
DELETE FROM user_interests WHERE user_id LIKE 'demo-f%';
DELETE FROM user_regions   WHERE user_id LIKE 'demo-f%';
DELETE FROM user_profiles  WHERE user_id LIKE 'demo-f%';
DELETE FROM users          WHERE id LIKE 'demo-f%';

INSERT INTO users (id, provider, provider_uid, nickname, birth_year, gender, country, last_seen_at) VALUES
 ('demo-f1', 'GOOGLE', 'demo-f1', '서아',   2001, 'FEMALE', 'KR', NOW() - INTERVAL 30 MINUTE),
 ('demo-f2', 'GOOGLE', 'demo-f2', 'みお',   2002, 'FEMALE', 'JP', NOW() - INTERVAL 5 HOUR),
 ('demo-f3', 'GOOGLE', 'demo-f3', '지우',   2000, 'FEMALE', 'KR', NOW() - INTERVAL 3 HOUR),
 ('demo-f4', 'GOOGLE', 'demo-f4', '채원',   1999, 'FEMALE', 'KR', NULL),
 ('demo-f5', 'GOOGLE', 'demo-f5', 'はるか', 2001, 'FEMALE', 'JP', NOW() - INTERVAL 2 DAY),
 ('demo-f6', 'GOOGLE', 'demo-f6', '다인',   2003, 'FEMALE', 'KR', NOW() - INTERVAL 1 HOUR),
 ('demo-f7', 'GOOGLE', 'demo-f7', 'なな',   2000, 'FEMALE', 'JP', NOW() - INTERVAL 1 DAY);

INSERT INTO user_profiles (user_id, photo_key, intro, updated_at) VALUES
 ('demo-f1', 'seed/p2.jpg', '주말엔 영화 보고 카페 가는 걸 좋아해요. 편하게 이야기해요!', NOW()),
 ('demo-f2', 'seed/p1.png', '東京に住んでいます。韓国ドラマが大好きです！', NOW()),
 ('demo-f3', 'seed/p3.jpg', NULL, NOW()),
 ('demo-f4', NULL, NULL, NOW()),
 ('demo-f5', 'seed/p1.png', NULL, NOW()),
 ('demo-f6', 'seed/p3.jpg', NULL, NOW()),
 ('demo-f7', 'seed/p2.jpg', NULL, NOW());

INSERT INTO user_regions (user_id, code) VALUES
 ('demo-f1', 'KR_SEOUL'), ('demo-f2', 'JP_TOKYO'), ('demo-f3', 'KR_BUSAN'), ('demo-f5', 'JP_OSAKA'),
 ('demo-f6', 'KR_SEOUL'), ('demo-f7', 'JP_TOKYO');

INSERT INTO user_interests (user_id, code) VALUES
 ('demo-f1', 'MOVIE'), ('demo-f1', 'MUSIC'), ('demo-f1', 'CAFE'),
 ('demo-f2', 'DRAMA'), ('demo-f2', 'KPOP');

-- ── 친구 목록 ── pair_key = CONCAT(LEAST(a,b),'_',GREATEST(a,b)) (앱이 채우는 칸, 함정 #2)
INSERT INTO friendships (id, requester_id, addressee_id, status, pair_key, created_at, accepted_at, requester_pinned_at, addressee_pinned_at) VALUES
 -- f1: 내가 신청한 쪽 → 내 고정 칸은 requester_pinned_at
 ('demo-fs1', @me, 'demo-f1', 'ACCEPTED', CONCAT(LEAST(@me,'demo-f1'),'_',GREATEST(@me,'demo-f1')),
   NOW() - INTERVAL 21 DAY, NOW() - INTERVAL 20 DAY, NOW() - INTERVAL 1 DAY, NULL),
 -- f2: 어제 수락 → 신규 등록(N). 상대가 나를 고정해도 **내 목록에는** 핀이 안 선다(보는 사람마다 따로).
 ('demo-fs2', 'demo-f2', @me, 'ACCEPTED', CONCAT(LEAST(@me,'demo-f2'),'_',GREATEST(@me,'demo-f2')),
   NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 1 DAY, NOW(), NULL),
 ('demo-fs3', 'demo-f3', @me, 'ACCEPTED', CONCAT(LEAST(@me,'demo-f3'),'_',GREATEST(@me,'demo-f3')),
   NOW() - INTERVAL 31 DAY, NOW() - INTERVAL 30 DAY, NULL, NULL),
 ('demo-fs4', @me, 'demo-f4', 'ACCEPTED', CONCAT(LEAST(@me,'demo-f4'),'_',GREATEST(@me,'demo-f4')),
   NOW() - INTERVAL 41 DAY, NOW() - INTERVAL 40 DAY, NULL, NULL),
 ('demo-fs5', 'demo-f5', @me, 'ACCEPTED', CONCAT(LEAST(@me,'demo-f5'),'_',GREATEST(@me,'demo-f5')),
   NOW() - INTERVAL 16 DAY, NOW() - INTERVAL 15 DAY, NULL, NULL);

-- ── 받은 신청 ──
INSERT INTO friendships (id, requester_id, addressee_id, status, pair_key, message, created_at, viewed_at) VALUES
 ('demo-fs6', 'demo-f6', @me, 'PENDING', CONCAT(LEAST(@me,'demo-f6'),'_',GREATEST(@me,'demo-f6')),
   '대화 즐거웠어요! 친구로 지내면서 사진 이야기 더 나눠요 :)', NOW() - INTERVAL 10 MINUTE, NULL),
 ('demo-fs7', 'demo-f7', @me, 'PENDING', CONCAT(LEAST(@me,'demo-f7'),'_',GREATEST(@me,'demo-f7')),
   'お話しできて楽しかったです！友達になってください', NOW() - INTERVAL 3 HOUR, NOW() - INTERVAL 2 HOUR);
