-- 무료 번역 쿼터를 **기획서대로** 다시 세운다(기획 4-2 · 5장 · 8-3).
--
-- 🚨 지금까지의 구현은 **값도 단위도 달랐다.**
--   ▸ 댓글: `free-comments-per-day: 2` = 번역 **건수** / 기획은 *"댓글창 **5회 호출**까지 무료"*
--   ▸ 채팅: `free-chat-targets-per-day: 2` = 하루 **상대 수** /
--           기획은 *"[대화방]은 **5개까지** 무료 번역. **대화방 삭제 전까지 계속** 번역 지원"*
--
-- ▸ 왜 표를 갈아야 하나
--   `daily_translate_targets`는 (user, 영업일, 상대)였다. 기획의 규칙은 **날짜와 무관**하고
--   **방**에 붙는다 — 한 번 번역이 열린 방은 그 방이 사라질 때까지 계속 번역된다.
--   날짜를 키에 넣어 둔 채로는 "대화방 삭제 전까지"를 표현할 수 없다.
--
-- ▸ "5개까지"는 **동시에 5개**다
--   방이 끝나면(`chat_rooms.status='ENDED'`) 자리가 빈다. 그래서 개수를 셀 때
--   행 수가 아니라 **살아 있는 방의 수**를 센다 — 이 표는 "어느 방을 열어 두었나"만 기억한다.
--   (행을 지우지 않는 이유: 끝난 방을 다시 열 일은 없고, 지우면 이력이 사라진다)
--
--   댓글창 5회는 `daily_usage`의 COMMENT_TRANSLATE 카운터를 그대로 쓴다 —
--   세는 대상이 "번역 건수"에서 "창 호출"로 바뀔 뿐 저장 구조는 같다.

CREATE TABLE translate_rooms (
    user_id    CHAR(36) NOT NULL COMMENT '번역을 켠 사람',
    room_id    CHAR(36) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, room_id),
    CONSTRAINT fk_translate_rooms_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_translate_rooms_room FOREIGN KEY (room_id)
        REFERENCES chat_rooms(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 옛 표는 규칙 자체가 사라졌으므로 남겨 둘 이유가 없다.
-- (하루치 임시 데이터라 옮길 값도 없다 — 옮기면 오히려 "그날의 상대"가
--  "영원한 방"으로 둔갑한다)
DROP TABLE IF EXISTS daily_translate_targets;
