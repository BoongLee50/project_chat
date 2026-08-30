-- **초기화되지 않는** 사용량(기획 5장 — 음성 메시지).
--
-- 기획서: *"음성 메시지는 계정별 5회 무료. **초기화 되지 않음.**"*
--
-- ▸ 왜 daily_usage로는 안 되나
--   그 표는 (user, 영업일, kind)라 매일 0으로 돌아온다. "평생 5회"는 날짜가 없는 값이다.
--   같은 표에 session_date를 고정값으로 넣어 흉내 내면, 하루치를 지우는 배치가
--   언젠가 이 행을 함께 지운다.
--
-- ▸ 왜 kind를 두나
--   지금 필요한 건 음성 하나뿐이지만, "평생 N회"는 앞으로도 나올 모양이다.
--   표를 하나 더 만드느니 kind로 나눠 둔다(daily_usage와 같은 구조라 읽기도 쉽다).
--
--   ⚠️ 이 표는 **어떤 배치도 지우지 않는다.** 지우는 순간 무료 횟수가 되살아난다.

CREATE TABLE lifetime_usage (
    user_id    CHAR(36)    NOT NULL,
    kind       VARCHAR(40) NOT NULL COMMENT 'VOICE_MESSAGE 등',
    used       INT         NOT NULL DEFAULT 0,
    updated_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, kind),
    CONSTRAINT fk_lifetime_usage_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
