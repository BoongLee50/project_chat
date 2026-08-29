-- Plan_3 ②단계 — 포스트 메인 사진 지정 (기획서 3-1 / docs/12 §2-4).
--
-- 달빛가든에 노출할 대표 사진 한 장을 고른다. ③단계의 열람 제한
-- ("무료 사용자는 상대의 메인 사진 1장만")이 이 값 위에 얹힌다.
--
-- ▸ 왜 post_photos.is_main 플래그가 아니라 posts.main_photo_id 인가
--   플래그로 두면 "한 포스트에 메인은 하나"를 DB가 지켜 주지 못한다
--   (부분 유니크 인덱스가 필요한데 MariaDB에 없다). 컬럼 하나에 id를 담으면
--   **구조상 둘이 될 수 없다.** 승계 규칙(메인을 지우면 다음 슬롯)도 UPDATE 한 번이다.
--
-- ▸ 왜 FOREIGN KEY를 걸지 않는가
--   post_photos.post_id → posts.id 가 이미 ON DELETE CASCADE다. 여기에
--   posts.main_photo_id → post_photos.id 를 걸면 **두 테이블이 순환 참조**가 된다.
--   InnoDB에서 순환 캐스케이드는 동작이 보장되지 않아(사용자 탈퇴로 posts가 지워질 때
--   터질 수 있다) 참조 무결성은 서비스가 지킨다:
--     · 등록  — 메인이 비어 있으면 새 사진이 메인
--     · 삭제  — 지운 게 메인이면 이웃 슬롯으로 승계
--     · 조회  — main_photo_id가 실제 사진 목록에 없으면 첫 슬롯으로 대체(방어)
--   조회 쪽이 방어하므로 값이 떠 있어도 화면이 비지 않는다.

ALTER TABLE posts
    ADD COLUMN main_photo_id CHAR(36) NULL
        COMMENT '달빛가든 대표 사진(post_photos.id). FK 없음 — 순환 캐스케이드 회피, 서비스가 관리';

-- 기존 포스트는 첫 슬롯(가장 먼저 올린 사진)을 메인으로 승계한다.
-- "최초 사진은 자동 메인"이라는 규칙을 과거 데이터에도 그대로 적용하는 것이다.
UPDATE posts p
SET p.main_photo_id = (
    SELECT ph.id FROM post_photos ph
    WHERE ph.post_id = p.id
    ORDER BY ph.order_idx
    LIMIT 1
)
WHERE p.main_photo_id IS NULL;
