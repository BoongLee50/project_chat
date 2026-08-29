-- Plan_3 ①단계 — 게이트 폐지에 딸려 사라지는 컬럼 정리.
--
-- 1) posts.one_liner  : "하루 한 마디"가 폐지됐다(달빛 한마디 이벤트가 그 자리를 대신한다).
--    달빛가든 카드와 [포스트 정보]에 나오는 문구는 이제 **프로필의 소개 한마디**
--    (user_profiles.intro)다 — 기획서 4-1의 "관심사와 자기소개 문구를 랜덤하게 출력".
--
-- 2) posts.window_started_at : 무료 사용자의 "등록 가능 창(1시간)"이 폐지됐다.
--    운영시간이 없어지면서 함께 사라진 개념이라 판정도 컬럼도 필요 없다.
--
-- ⚠️ 영업일(session_date)의 경계는 이 마이그레이션이 아니라 **설정**이 정한다
--    (app.session.rollover-hour, 06시 → 18시). 이미 저장된 행은 옛 기준으로 찍혀 있으므로
--    운영 데이터가 쌓인 뒤에 경계를 바꿀 때는 **반드시 경계 시각 정각에 배포**할 것(docs/12 §6-1).

ALTER TABLE posts
    DROP COLUMN one_liner,
    DROP COLUMN window_started_at;
