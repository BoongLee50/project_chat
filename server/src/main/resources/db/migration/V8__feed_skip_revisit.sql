-- V8 — 스킵한 상대가 "갱신"하면 피드에 다시 보이게 하기 위한 시각 컬럼. (기획 4-1)
--
-- 스킵은 영구 제외가 아니다. 두 경우엔 다시 보여야 한다.
--   ① 볼 포스트가 다 떨어졌을 때  → V8 없이 이미 처리됨(GardenService가 재조회)
--   ② 상대가 **사진이나 프로필을 갱신**했을 때  → 여기서 필요한 게 "언제 갱신했나"다
--
-- 판정은 서버 쿼리에서 시각 비교로 한다 — 스킵한 시각보다 갱신이 나중이면 다시 노출.
-- 클라는 평소처럼 GET /feed만 부르므로 **추가 통신이 없다.**
--
-- 재등장이 폭주하지 않는 이유: 다시 뜬 걸 또 스킵하면 스킵 시각이 갱신 시각보다
-- 나중이 되어 조건이 닫힌다. 즉 **갱신 1회당 재등장 1회**가 저절로 보장된다.
-- (그래서 insertSkip을 INSERT IGNORE → ON DUPLICATE KEY UPDATE로 바꾼다.)

-- 포스트 쪽 갱신 시각. 사진 등록·삭제·하루 한마디 수정 때 서버가 찍는다.
-- post_photos.created_at으로는 **삭제·교체를 잡을 수 없어** 포스트에 따로 둔다.
ALTER TABLE posts
    ADD COLUMN content_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT '사진/한마디가 마지막으로 바뀐 시각 — 스킵 재노출 판정용';

-- 기존 행은 공유 시각(없으면 생성 시각)으로 채운다. 과거 글이 갑자기
-- "방금 갱신됨"으로 보여 한꺼번에 재노출되는 것을 막기 위함.
UPDATE posts SET content_updated_at = COALESCE(published_at, content_updated_at);

CREATE INDEX ix_posts_content_updated ON posts (content_updated_at);

-- 프로필 쪽은 user_profiles.updated_at(ON UPDATE CURRENT_TIMESTAMP)이 이미 있다.
-- 다만 **관심사·지역은 별도 테이블**이라 그것만으로는 안 잡힌다 →
-- 서비스가 그 둘을 바꿀 때 user_profiles를 함께 touch 한다(V8 이후 코드).
