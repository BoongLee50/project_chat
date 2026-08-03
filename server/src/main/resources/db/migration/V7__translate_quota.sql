-- V7 — 번역 무료 쿼터 중 "채팅 2명"을 세기 위한 테이블.
--
-- daily_usage는 (user, date, kind) 하나에 used_count 하나뿐이라 횟수는 세도
-- **누구와 번역했는지**는 기억하지 못한다. 기획(01 §1.4)의 채팅 번역 무료는
-- "매일 2회"가 아니라 "매일 2명"이라, 같은 상대와의 두 번째 번역은 공짜여야 한다.
-- 그래서 상대를 행으로 남긴다 — 행 수가 곧 사용한 사람 수다.
--
-- 댓글 번역(2회)은 횟수라서 기존 daily_usage.used_count로 충분하다.
-- 프로필 보기 번역은 항상 무료라 아무것도 기록하지 않는다.

CREATE TABLE daily_translate_targets (
    user_id      CHAR(36) NOT NULL,
    session_date DATE     NOT NULL,
    target_id    CHAR(36) NOT NULL COMMENT '번역을 연 상대 userId',
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, session_date, target_id),
    CONSTRAINT fk_daily_translate_targets_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 06시 배치가 지난 영업일을 지운다(daily_usage와 같은 주기).
CREATE INDEX idx_daily_translate_targets_date ON daily_translate_targets (session_date);
