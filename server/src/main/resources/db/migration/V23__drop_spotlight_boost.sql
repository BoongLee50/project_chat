-- 사장된 SPOTLIGHT_BOOST를 enum에서 지운다. (Plan_3에서 스포트라이트 폐지 / 기획 답변 2026-09-06)
--
-- 코드·설정·문구에서는 ①단계에 이미 지워졌는데 **DB enum에만 남아 있었다.**
-- V6를 고칠 수는 없으니(Flyway 체크섬) 여기서 좁힌다.
--
-- 값이 남아 있으면 실제로 문제가 된다:
--   1) 없는 상품을 DB가 계속 "가능한 값"이라고 말한다 — 스키마를 읽는 사람이 오해한다
--   2) 잘못된 코드가 SPOTLIGHT_BOOST를 넣어도 **DB가 막아 주지 못한다**
--
-- 남아 있는 행은 먼저 지운다. 부스트는 1시간짜리 활성이고 재고는 이미 팔지 않는 상품이라
-- 지워도 잃을 것이 없다(운영 데이터가 생기기 전이다).

DELETE FROM boost_activations WHERE kind = 'SPOTLIGHT_BOOST';
DELETE FROM boost_inventory  WHERE kind = 'SPOTLIGHT_BOOST';

ALTER TABLE boost_inventory
    MODIFY COLUMN kind ENUM('POST_BOOST') NOT NULL;

ALTER TABLE boost_activations
    MODIFY COLUMN kind ENUM('POST_BOOST') NOT NULL;
