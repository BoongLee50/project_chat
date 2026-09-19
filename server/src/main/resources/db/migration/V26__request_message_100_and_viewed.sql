-- ① 대화 신청 · 친구 신청의 한마디를 **100자로 통일**한다(기획사항 2026-09-19 변경사항).
--
-- "대화신청과 친구신청의 요청문구의 최대숫자는 100자로 변경 및 통일.
--  공백, 이모지, 특수문자 까지 모두 문구로 취급. 줄바꾸기는 불가."
--
-- ▸ 대화 신청 150 → 100 : 🚨 **좁히는 방향**이다(V25와 같은 경우).
--   넘치는 행이 하나라도 있으면 MariaDB가 `Data too long`으로 ALTER를 거부하고
--   Flyway가 실패해 **서버가 안 뜬다.** 먼저 잘라 둔다(출시 전이라 개발 데이터뿐이다).
-- ▸ 친구 신청 25 → 100 : 넓히는 방향이라 기존 행은 그대로 산다.
--
-- ⚠️ "모든 문자를 문구로 취급" — 한도는 **코드포인트**로 센다. VARCHAR(n)도 utf8mb4에서
--   코드포인트 n개이고, 서버도 `codePointCount`로 센다. 클라도 같은 단위로 세야
--   "화면은 받았는데 서버가 거절"이 생기지 않는다(👨‍👩‍👧 같은 결합 이모지는 여러 개로 센다).
--
-- ▸ 줄바꿈은 여기서 막지 않는다 — 서버가 저장 전에 공백으로 바꾼다(ChatService·FriendService).

UPDATE chat_requests
SET message = LEFT(message, 100)
WHERE CHAR_LENGTH(message) > 100;

ALTER TABLE chat_requests
    MODIFY COLUMN message VARCHAR(100) NOT NULL COMMENT '대화 신청 한마디(100자, 기획사항 2026-09-19)';

ALTER TABLE friendships
    MODIFY COLUMN message VARCHAR(100) NULL COMMENT '친구 신청 한마디(100자, 기획사항 2026-09-19)';

-- ② 받은 신청을 **열어 봤는가**(대화방 [받은 신청] 셀의 미확인 표시 `N`).
--
-- 기획서 260919 6-2: "[받은 신청]의 화면 구성과 기능은 [대화 목록]창과 동일".
-- [대화 목록]의 미확인 표시는 "마지막 메시지를 아직 확인하지 않았을 경우"이므로,
-- 신청에서는 **그 신청을 아직 열어 보지 않았을 경우**가 된다(260906판의 "포스트 정보창을
-- 호출하지 않은 목록은 N" 과 같은 뜻). 지금까지는 칼럼이 없어 대기 중이면 무조건 N이었다.
--
-- 받는 사람이 그 신청의 [포스트 정보](받은 신청 팝업)를 열 때 채운다. NULL이면 안 열어 봤다.

ALTER TABLE chat_requests
    ADD COLUMN viewed_at DATETIME NULL COMMENT '받는 사람이 처음 열어 본 시각(V26). NULL이면 미확인';
