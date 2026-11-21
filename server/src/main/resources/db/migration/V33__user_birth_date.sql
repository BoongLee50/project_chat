-- 온보딩 STEP 2 [생년월일] — 출생년도만 받던 것을 **연·월·일**로 받는다(그래픽 소스 `로그인 화면` 2026-11-21).
--
-- birth_year는 그대로 둔다 — 가든·포스트 정보·친구 목록이 나이를 이 칸으로 센다.
-- 가입 때 birth_date를 받으면 서버가 birth_year도 함께 채운다(같은 해).
-- 기존 회원은 날짜를 모르므로 NULL로 남는다(만 18세 검사도 그때는 연 단위 그대로).
ALTER TABLE users
    ADD COLUMN birth_date DATE NULL AFTER birth_year;
