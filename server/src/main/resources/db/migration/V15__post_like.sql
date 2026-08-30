-- 포스트 좋아요 — **한 사람이 한 포스트에 하루 한 번**(기획 4-1).
--
-- 지금까지는 `post_stats.likes`를 그냥 +1 했다. 카운터에는 **누가 눌렀는지가 없어서**
-- 같은 사람이 몇 번이고 누를 수 있었다(사용자가 앱에서 확인해 알려 준 결함).
--
-- 달빛 한마디의 좋아요(`daily_answer_likes`, V14)는 처음부터 행으로 두어 막고 있었다.
-- 같은 방식으로 맞춘다 — 규칙이 같으면 구조도 같아야 나중에 갈라지지 않는다.
--
-- ▸ 왜 (post_id, user_id)가 곧 "하루 한 번"인가
--   posts는 영업일마다 새 행이다(uk_posts_user_session). 그래서 포스트 id가 바뀌면
--   다음 날이고, 이 PK만으로 "하루에 한 사람 한 번"이 저절로 보장된다.
--   session_date를 따로 들고 다닐 필요가 없다.
--
-- ▸ post_stats.likes는 그대로 둔다
--   Engage 전환율이 그 값을 쓴다(③단계). 이 표는 **중복을 막는 문지기**이고,
--   실제로 처음 눌렸을 때만 카운터가 올라간다.

CREATE TABLE post_likes (
    post_id    CHAR(36) NOT NULL,
    user_id    CHAR(36) NOT NULL COMMENT '좋아요를 누른 사람',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, user_id),
    CONSTRAINT fk_post_likes_post FOREIGN KEY (post_id)
        REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_post_likes_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
