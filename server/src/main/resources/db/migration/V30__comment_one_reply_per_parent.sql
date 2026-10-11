-- 댓글 하나에 답글은 하나만(사용자 확정 2026-10-11, 포스트·달빛 한마디 공통).
--
--   1차 댓글 → 2차(게시자만, **1차 하나당 1번**) → 3차(1차 쓴 사람만, **2차 하나당 1번**)
--   그래서 한 1차 댓글 아래는 언제나 한 줄이고 가지가 갈라지지 않는다 = **parent_id가 겹치지 않는다**.
--
-- 서버(`CommentService`)가 먼저 막지만, 보내기를 두 번 누르는 것처럼 **동시에 들어온 두 요청**은
-- "아직 답글이 없다"를 둘 다 통과한다. 그래서 DB가 마지막으로 막는다(유니크 인덱스).
-- 1차 댓글은 parent_id가 NULL이고, 유니크 인덱스는 NULL끼리는 겹쳐도 된다 — 1차는 몇 개든 그대로다.
--
-- ① 규칙 전에 이미 갈라진 줄을 먼저 정리한다(그대로 두면 인덱스가 안 만들어져 **서버가 안 뜬다** — 함정 #76과 같은 원리).
--    부모마다 **가장 먼저 달린 답글 하나**를 남기고 나머지를 지운다. 지우는 답글 밑의 3차도 함께.
--    (2026-10-11 개발 DB: 한마디 더미 댓글 하나에 2차가 두 개 — 규칙이 코드에 없을 때 폰에서 시험하다 생긴 것)

CREATE TEMPORARY TABLE tmp_extra_replies AS
SELECT c.id
FROM comments c
WHERE c.parent_id IS NOT NULL
  AND EXISTS (SELECT 1 FROM comments e
              WHERE e.parent_id = c.parent_id
                AND (e.created_at < c.created_at OR (e.created_at = c.created_at AND e.id < c.id)));

DELETE FROM comments WHERE parent_id IN (SELECT id FROM tmp_extra_replies);
DELETE FROM comments WHERE id IN (SELECT id FROM tmp_extra_replies);
DROP TEMPORARY TABLE tmp_extra_replies;

-- ② 일반 인덱스를 유니크로 바꾼다(답글 찾기에 쓰던 인덱스 그대로, 겹침만 금지).
ALTER TABLE comments
    DROP INDEX ix_post_comments_parent,
    ADD UNIQUE KEY uk_comments_parent (parent_id);
