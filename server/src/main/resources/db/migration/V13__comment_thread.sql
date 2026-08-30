-- Plan_3 ④단계 — 댓글 개편. (기획서 4-2 / 8-2 / 8-3)
--
-- 세 화면(포스트 댓글 · 달빛 한마디 상세 · 내 한마디)의 댓글 규칙이 **완전히 같다** —
-- 3단계까지 · 50자 · 이미지 1장 · 번역. 그래서 한 구조로 만들어 ⑤단계에서 재사용한다.
--
-- 1) body 25 → 50자
--    기획서가 세 곳 모두에서 "최대 50자"로 못박았다.
--
-- 2) parent_id / depth — 3단계 대댓글
--    지금은 완전 평면이다. depth를 따로 두는 이유는 **"3단계까지"를 한 줄로 판정**하기
--    위해서다. parent_id만 있으면 깊이를 알려고 매번 조상을 거슬러 올라가야 하고,
--    그 판정이 빠지는 순간 4단계가 조용히 생긴다.
--
--    ▸ parent_id에 FK를 걸지 않는다 — V11(posts.main_photo_id)과 같은 이유다.
--      InnoDB는 **자기 참조 테이블의 캐스케이드가 기대대로 동작하지 않을 수 있다.**
--      게다가 필요도 없다: post_id → posts 의 ON DELETE CASCADE가 이미 포스트가 지워질 때
--      댓글 트리를 통째로 지운다. 부모-자식 정합성은 서비스가 지킨다
--      (부모가 같은 포스트인지 확인하고, depth를 부모+1로 계산한다).
--
-- 3) image_key — 첨부 이미지 1장
--    포스트 사진과 같은 흐름(업로드 URL 발급 → 직접 업로드 → 키 등록). 한 장뿐이라
--    별도 테이블 없이 컬럼 하나로 둔다. 다운로드 URL은 저장하지 않고 응답 시점에 계산한다.

ALTER TABLE post_comments
    MODIFY COLUMN body VARCHAR(50) NOT NULL COMMENT '최대 50자(기획 4-2)',
    ADD COLUMN parent_id CHAR(36) NULL
        COMMENT '부모 댓글. FK 없음 — 자기 참조 캐스케이드 회피, 정합성은 서비스가 지킨다',
    ADD COLUMN depth TINYINT NOT NULL DEFAULT 1
        COMMENT '1=댓글, 2=대댓글, 3=대대댓글. 3을 넘으면 서버가 거절한다',
    ADD COLUMN image_key VARCHAR(255) NULL
        COMMENT '첨부 이미지 1장(선택). 다운로드 URL은 응답 시점에 계산',
    ADD KEY ix_post_comments_parent (parent_id);
