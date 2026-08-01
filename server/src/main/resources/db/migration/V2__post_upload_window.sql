-- 포스트 등록 규칙(Plan_2 3-1) 지원 컬럼 추가
-- · 일반 사용자는 "접속 시간 기준 1시간" 동안만 사진 등록 가능 → 창 시작 시각을 기록해야 함
--   (프라임/앨범패스 사용자는 시간 제한 없음 → 남은 시간 대신 "PASS" 표시)
-- · 사진 교체 횟수 제한(일반 2회/일, 패스 20회/일) → 일자별 카운터
-- session_date 단위로 하루가 관리되므로 두 값 모두 posts row에 둔다.

ALTER TABLE posts
    ADD COLUMN window_started_at DATETIME NULL COMMENT '등록 가능 창 시작(첫 진입 시각). 일반 사용자 1시간 계산 기준',
    ADD COLUMN replace_count     INT NOT NULL DEFAULT 0 COMMENT '당일 사진 교체(삭제) 횟수';
