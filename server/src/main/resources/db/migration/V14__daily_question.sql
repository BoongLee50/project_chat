-- Plan_3 ⑤단계 — 달빛 한마디 이벤트. (기획서 8장)
--
-- 매일 하나의 질문에 **한마디(100자) + 사진 1장(선택)** 으로 답하고 서로 보는 이벤트.
-- KST 18시에 모든 정보가 초기화되고 새 질문이 나온다(영업일 경계와 같은 시계 — ①단계).
--
-- 🚨 이름에 콘텐츠를 넣지 않았다(docs/12 §6 E). "달빛우편"이 "달빛 한마디"가 된 전례가 있고,
--    이름이 또 바뀌어도 **ARB 문구만** 고치면 되도록 `daily_question` 처럼 역할로 짓는다.

-- ============================================================
-- 1) 댓글을 포스트 전용에서 **공용**으로 넓힌다
-- ============================================================
-- ④단계에서 만든 3단계·50자·이미지 규칙을 달빛 한마디가 **그대로 쓴다**(기획서 8-2·8-3이
-- 4-2와 문장까지 같다). 표를 하나 더 만들면 규칙이 두 벌이 되어 언젠가 갈라진다.
--
-- ⚠️ posts로 걸려 있던 FK가 사라진다. 대상이 두 종류가 되면 한 컬럼으로 FK를 걸 수 없다.
--    그래서 **지난 영업일 정리 배치가 주인 없는 댓글을 함께 지운다**(V14 이후 코드).

ALTER TABLE post_comments
    DROP FOREIGN KEY fk_post_comments_post;

ALTER TABLE post_comments
    ADD COLUMN target_type ENUM('POST','DAILY_ANSWER') NOT NULL DEFAULT 'POST'
        COMMENT '무엇에 달린 댓글인가',
    ADD COLUMN target_id CHAR(36) NULL COMMENT '포스트 id 또는 달빛 한마디 답변 id';

UPDATE post_comments SET target_id = post_id WHERE target_id IS NULL;

ALTER TABLE post_comments
    MODIFY COLUMN target_id CHAR(36) NOT NULL,
    DROP COLUMN post_id,
    ADD KEY ix_comments_target (target_type, target_id, created_at);

RENAME TABLE post_comments TO comments;

-- ============================================================
-- 2) 오늘의 질문
-- ============================================================
-- 영업일마다 하나. session_date를 유니크로 두어 **하루에 두 질문이 생길 수 없게** 한다.
--
-- ⚠️ 본문을 한국어·일본어 두 벌로 둔다. 화면 문구(ARB)와 달리 질문은 **콘텐츠**라
--    ARB에 넣을 수 없고, 한·일 동시 오픈이라 한 벌로는 한쪽이 읽지 못한다.
CREATE TABLE daily_questions (
    id           CHAR(36)     NOT NULL,
    session_date DATE         NOT NULL,
    body_ko      VARCHAR(200) NOT NULL,
    body_ja      VARCHAR(200) NOT NULL,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_daily_questions_date (session_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 질문 후보. 오늘 질문이 없으면 여기서 **아직 안 쓴 것**을 하나 꺼내 쓴다.
-- 기획이 질문을 채워 넣는 곳이고, 다 쓰면 처음부터 다시 돈다.
CREATE TABLE daily_question_bank (
    id      INT          NOT NULL AUTO_INCREMENT,
    body_ko VARCHAR(200) NOT NULL,
    body_ja VARCHAR(200) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO daily_question_bank (body_ko, body_ja) VALUES
    ('오늘 하루, 가장 설렜던 순간은?',      '今日一日で、いちばん心が弾んだ瞬間は？'),
    ('요즘 자꾸 듣게 되는 노래가 있나요?',  '最近くり返し聴いている曲はありますか？'),
    ('오늘 본 것 중 가장 예뻤던 풍경은?',   '今日見た中でいちばんきれいだった景色は？'),
    ('나를 웃게 만든 사소한 일은?',        'ふと笑ってしまった小さな出来事は？'),
    ('요즘 가장 자주 가는 장소는 어디인가요?', '最近いちばんよく行く場所はどこですか？'),
    ('오늘 누군가에게 고맙다고 느낀 순간은?', '今日、誰かに感謝した瞬間は？'),
    ('내일의 나에게 한마디 한다면?',        '明日の自分にひとこと言うなら？');

-- ============================================================
-- 3) 답변 — 하루에 한 사람 한 글
-- ============================================================
CREATE TABLE daily_answers (
    id           CHAR(36)     NOT NULL,
    question_id  CHAR(36)     NOT NULL,
    user_id      CHAR(36)     NOT NULL,
    session_date DATE         NOT NULL COMMENT '초기화·정리 기준(질문과 같은 값)',
    body         VARCHAR(100) NOT NULL COMMENT '최대 100자(기획 8-3)',
    image_key    VARCHAR(255) NULL     COMMENT '메인 이미지 1장(선택)',
    created_at   DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    -- 하루에 한 사람이 두 번 답하지 못하게 **DB가** 막는다.
    UNIQUE KEY uk_daily_answers_question_user (question_id, user_id),
    KEY ix_daily_answers_session (session_date, created_at),
    CONSTRAINT fk_daily_answers_question FOREIGN KEY (question_id)
        REFERENCES daily_questions(id) ON DELETE CASCADE,
    CONSTRAINT fk_daily_answers_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 좋아요 — 사람마다 한 번. 카운터가 아니라 행으로 두는 이유는
-- **누가 눌렀는지**를 알아야 두 번 세지 않고, 화면에서 눌린 상태를 보여줄 수 있어서다.
CREATE TABLE daily_answer_likes (
    answer_id  CHAR(36) NOT NULL,
    user_id    CHAR(36) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (answer_id, user_id),
    CONSTRAINT fk_daily_answer_likes_answer FOREIGN KEY (answer_id)
        REFERENCES daily_answers(id) ON DELETE CASCADE,
    CONSTRAINT fk_daily_answer_likes_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
