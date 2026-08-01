-- 채팅 도메인 지원
--
-- 1) chat_messages.body 길이 정정 (25 → 500)
--    기획서 5장의 "개별 대화목록의 메시지는 최대 25자까지만 보여주고 나머지는 생략한다"는
--    **대화방 목록의 미리보기 말줄임** 규칙인데, V1 스키마가 이를 메시지 본문 길이 제한으로
--    잘못 반영해 두었다. 실제 채팅 본문은 그보다 길 수 있으므로 넉넉히 확장하고,
--    25자 말줄임은 클라이언트(목록 화면)에서 처리한다.
--
-- 2) chat_rooms.type — 매칭 대화(MATCH)와 친구 상시 대화방(FRIEND) 구분.
--    FRIEND 방은 야간 게이트/30분 자동삭제 대상에서 제외된다(친구는 24시간 대화, 02 문서 §1.6).
--
-- 3) daily_usage — 일일 무료 쿼터(대화 신청 2회, 댓글/채팅 번역).
--    06시 초기화 배치가 지난 session_date를 정리한다.

ALTER TABLE chat_messages
    MODIFY COLUMN body VARCHAR(500) NOT NULL;

ALTER TABLE chat_rooms
    ADD COLUMN type ENUM('MATCH','FRIEND') NOT NULL DEFAULT 'MATCH'
        COMMENT '매칭 대화 / 친구 상시 대화방(게이트·자동삭제 예외)';

CREATE TABLE daily_usage (
    user_id      CHAR(36) NOT NULL,
    session_date DATE     NOT NULL,
    kind         ENUM('CHAT_REQUEST','COMMENT_TRANSLATE','CHAT_TRANSLATE') NOT NULL,
    used_count   INT      NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, session_date, kind),
    CONSTRAINT fk_daily_usage_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
