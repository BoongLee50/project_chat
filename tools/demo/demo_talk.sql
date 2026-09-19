-- 대화방 UI 확인용 데모 데이터(2026-09-19). 전부 'demo-' 접두어다.
--
-- 받는 사람은 **[LINE] 버튼으로 목 로그인한 계정**(provider_uid = 'mock-dev-line')이다.
-- 그 계정으로 한 번 로그인·프로필 생성을 마친 뒤에 돌릴 것 — 없으면 @me가 NULL이라 아무것도 안 들어간다.
--
--   mysql -umoonlighttalk -pmoonlighttalk moonlighttalk --default-character-set=utf8mb4 < tools/demo/demo_talk.sql
--
-- 들어가는 것: 대화 목록 3칸(안 읽음 N · 일본어 글 · 음성 뒤 글 미리보기 · 사진 없는 빈 칸)
--            받은 신청 2칸(안 열어 본 일본어 신청 · 열어 본 한국어 신청).
-- 사진은 `server/server/uploads/seed/p1~p3`를 쓴다(저장소에 없으면 사진 칸만 빈다).
-- ⚠️ 접속 표시(ON)는 소켓이 붙어야 켜지므로 데모로는 못 본다.
--
-- 지우기: 아래 CLEANUP 블록만 돌리면 된다(다시 돌려도 먼저 비운 뒤 넣는다).
SET @me = (SELECT id FROM users WHERE provider = 'LINE' AND provider_uid = 'mock-dev-line');

-- CLEANUP (먼저 한 번 비운다)
DELETE FROM chat_messages WHERE id LIKE 'demo-%' OR room_id IN (SELECT id FROM chat_rooms WHERE user_a LIKE 'demo-%' OR user_b LIKE 'demo-%');
DELETE FROM translate_rooms WHERE room_id IN (SELECT id FROM chat_rooms WHERE user_a LIKE 'demo-%' OR user_b LIKE 'demo-%');
DELETE FROM chat_rooms    WHERE id LIKE 'demo-%' OR user_a LIKE 'demo-%' OR user_b LIKE 'demo-%';
DELETE FROM chat_requests WHERE id LIKE 'demo-%';
DELETE FROM user_regions  WHERE user_id LIKE 'demo-%';
DELETE FROM user_profiles WHERE user_id LIKE 'demo-%';
DELETE FROM users         WHERE id LIKE 'demo-%';

INSERT INTO users (id, provider, provider_uid, nickname, birth_year, gender, country) VALUES
 ('demo-u1', 'GOOGLE', 'demo-u1', '하윤', 2001, 'FEMALE', 'KR'),
 ('demo-u2', 'GOOGLE', 'demo-u2', '예린', 2000, 'FEMALE', 'KR'),
 ('demo-u3', 'GOOGLE', 'demo-u3', '미유', 2002, 'FEMALE', 'JP'),
 ('demo-u4', 'GOOGLE', 'demo-u4', '민서', 1999, 'FEMALE', 'KR'),
 ('demo-u5', 'GOOGLE', 'demo-u5', '수아', 2003, 'FEMALE', 'KR');

INSERT INTO user_profiles (user_id, photo_key, intro, updated_at) VALUES
 ('demo-u1', 'seed/p2.jpg', '영화 좋아해요', NOW()),
 ('demo-u2', 'seed/p3.jpg', NULL, NOW()),
 ('demo-u3', 'seed/p1.png', 'よろしくね', NOW()),
 ('demo-u4', NULL, NULL, NOW()),          -- 사진 없는 셀(빈 칸)이 어떻게 보이는지
 ('demo-u5', 'seed/p3.jpg', NULL, NOW());

INSERT INTO user_regions (user_id, code) VALUES ('demo-u3', 'JP_TOKYO'), ('demo-u1', 'KR_SEOUL');

-- ── 대화 목록 ──
INSERT INTO chat_rooms (id, user_a, user_b, status, type, active_pair_key, created_at) VALUES
 ('demo-r1', @me, 'demo-u1', 'ACTIVE', 'MATCH', CONCAT(LEAST(@me,'demo-u1'),'_',GREATEST(@me,'demo-u1')), NOW() - INTERVAL 2 DAY),
 ('demo-r2', @me, 'demo-u2', 'ACTIVE', 'MATCH', CONCAT(LEAST(@me,'demo-u2'),'_',GREATEST(@me,'demo-u2')), NOW() - INTERVAL 3 DAY),
 ('demo-r3', @me, 'demo-u4', 'ACTIVE', 'MATCH', CONCAT(LEAST(@me,'demo-u4'),'_',GREATEST(@me,'demo-u4')), NOW() - INTERVAL 5 DAY);

-- r1: 5분 전, 안 읽음 → N + 탭 숫자. 25자가 넘는 글(…로 잘리는지).
INSERT INTO chat_messages (id, room_id, sender_id, type, body, created_at, read_at) VALUES
 ('demo-m1', 'demo-r1', @me,       'TEXT', '그 영화 봤어요?', NOW() - INTERVAL 20 MINUTE, NOW()),
 ('demo-m2', 'demo-r1', 'demo-u1', 'TEXT', '저도 그 영화 정말 좋아해요! 다음에 또 이야기해요 :)', NOW() - INTERVAL 5 MINUTE, NULL);
-- r2: 28분 전, 다 읽음 → N 없음. 일본어 글.
INSERT INTO chat_messages (id, room_id, sender_id, type, body, created_at, read_at) VALUES
 ('demo-m3', 'demo-r2', 'demo-u2', 'TEXT', '今度またお話したいです！よろしくお願いします', NOW() - INTERVAL 28 MINUTE, NOW());
-- r3: 글 뒤에 음성이 마지막 → 미리보기는 그 전 글, 시각은 음성(3시간 전).
INSERT INTO chat_messages (id, room_id, sender_id, type, body, audio_key, audio_duration_ms, created_at, read_at) VALUES
 ('demo-m4', 'demo-r3', 'demo-u4', 'TEXT',  '또 연락할게요! 좋은 밤 보내세요', NULL, NULL, NOW() - INTERVAL 4 HOUR, NOW()),
 ('demo-m5', 'demo-r3', 'demo-u4', 'VOICE', '', 'voice/demo.m4a', 3000, NOW() - INTERVAL 3 HOUR, NOW());

-- ── 받은 신청 ──
-- q1: 일본어, 안 열어 봄 → N + 탭 숫자. 팝업에서 [원문보기]·번역을 보는 대상.
INSERT INTO chat_requests (id, from_user, to_user, message, status, luna_cost, created_at, viewed_at) VALUES
 ('demo-q1', 'demo-u3', @me, 'はじめまして！仲良くなれたら、いろいろお話ししたいです😊よろしくお願いします！', 'PENDING', 0, NOW() - INTERVAL 5 MINUTE, NULL),
 ('demo-q2', 'demo-u5', @me, '안녕하세요! 프로필 보고 연락드려요. 이야기 나눠요', 'PENDING', 0, NOW() - INTERVAL 2 HOUR, NOW() - INTERVAL 1 HOUR);
