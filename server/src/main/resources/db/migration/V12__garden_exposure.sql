-- Plan_3 ③단계 — 달빛가든 노출 알고리즘이 요구하는 두 가지. (기획서 4-1 / docs/12 §4-2)
--
-- 1) post_stats.comments
--    Engage 전환율의 분자가 **{좋아요×1 + 댓글×2 + 대화신청×4}** 로 바뀌었다.
--    좋아요·대화신청은 이미 세고 있었지만 **댓글은 세고 있지 않았다.**
--    실시간으로 post_comments를 COUNT 하지 않고 카운터를 두는 이유는 나머지 둘과 같다 —
--    분모(노출)가 커질수록 매 요청 COUNT가 비싸지고, 셋의 초기화 시점(영업일)이 같아야 한다.
--
-- 2) feed_exposures
--    "한 번 노출된 상대는 그 사용자에게 **15분간 제외**"를 판정할 곳이 없었다.
--    feed_skips는 **사용자가 넘긴 것**(하루 단위)이라 뜻이 다르다 — 스킵하지 않고 그냥
--    지나간 상대도 15분은 다시 안 나와야 한다.
--
--    (user_id, target_user_id)를 PK로 두고 **마지막 노출 시각만 덮어쓴다.** 이력을 남기지
--    않는 이유는 판정에 "마지막으로 언제 보여줬나" 하나만 필요하기 때문이다.
--    행 수는 (활성 사용자 × 후보 수)로 묶이고, 지난 영업일 정리 배치가 오래된 행을 지운다.

ALTER TABLE post_stats
    ADD COLUMN comments INT NOT NULL DEFAULT 0
        COMMENT 'Engage 전환율 분자(댓글×2). 영업일 단위로 초기화된다';

CREATE TABLE feed_exposures (
    user_id        CHAR(36) NOT NULL COMMENT '본 사람',
    target_user_id CHAR(36) NOT NULL COMMENT '보여진 사람',
    exposed_at     DATETIME NOT NULL COMMENT '마지막으로 보여준 시각 — 15분 제외 판정 기준',
    PRIMARY KEY (user_id, target_user_id),
    KEY ix_feed_exposures_at (exposed_at),
    CONSTRAINT fk_feed_exposures_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_feed_exposures_target FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
