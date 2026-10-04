-- 기획서 261002 8-1 [작성하기] — 프로필이 네 칸(사진·자기소개·관심사·활동 지역)으로 바뀌었다.
--
-- 1) 프로필 사진이 두 장이 된다.
--    · photo_key       = **얼굴 사진** — 친구·대화 목록 같은 간략한 목록이 쓴다(기존 그대로)
--    · main_photo_key  = **자유 사진** — [미리 보기]·[프로필 보기]의 큰 메인 사진(새 칸)
--    기존 photo_key를 얼굴 칸으로 남기는 이유: 목록·셀·포스트 정보가 이미 이 칸을 읽고 있다.
ALTER TABLE user_profiles
    ADD COLUMN main_photo_key VARCHAR(255) NULL AFTER photo_key;

-- 2) 자기소개 50자 → **300자**(띄어쓰기 포함). 넓히는 방향이라 잘리는 행이 없다.
ALTER TABLE user_profiles
    MODIFY COLUMN intro VARCHAR(300) NULL;

-- 3) 활동 지역 최대 2곳 → **1곳**. 좁히는 방향이라 넘치는 행을 먼저 지운다(V25·V26과 같은 원칙).
--    순서 칼럼이 없어 "먼저 고른 것"을 알 수 없으므로 코드가 작은 쪽 하나를 남긴다.
DELETE r
FROM user_regions r
JOIN user_regions keep_row
  ON keep_row.user_id = r.user_id
 AND keep_row.code < r.code;
