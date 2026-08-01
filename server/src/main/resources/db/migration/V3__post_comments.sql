-- 포스트 댓글(기획서 4-2, 01 문서 §1.4)
-- 최초 스키마(V1) 설계에서 누락되어 있던 테이블. 달빛가든 도메인 구현과 함께 추가한다.
-- · 해당 포스트에 대한 댓글만 가능(대댓글 없음)
-- · 최대 25자
-- · 포스트는 영업일 단위로 초기화되므로 댓글도 posts 삭제 시 함께 정리된다(ON DELETE CASCADE)

CREATE TABLE post_comments (
    id         CHAR(36)    NOT NULL,
    post_id    CHAR(36)    NOT NULL,
    author_id  CHAR(36)    NOT NULL,
    body       VARCHAR(25) NOT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    KEY ix_post_comments_post (post_id, created_at),
    CONSTRAINT fk_post_comments_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_post_comments_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
