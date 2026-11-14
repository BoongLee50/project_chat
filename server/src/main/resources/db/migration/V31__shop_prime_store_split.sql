-- V31 — 상점: 프라임 구독분 / 상점 구매분을 나눠 담는다 (기획서 261111 10-2·10-3·10-4, 2026-11-14)
--
-- 기획서 261111에서 루나 상점이 없어지고 부스트·포스트 앨범·자동 번역을 **현금으로 하나씩** 산다.
-- 관리 화면은 [프라임 구독분]과 [상점 구매분]을 따로 보여 주고 **프라임 구독분을 먼저 쓴다**.
--
-- 사용자 결정(2026-11-14):
--   · 프라임 부스트는 **매달 10개로 다시 채운다**(남은 건 사라짐) · 구독이 끝나면 프라임 구독분도 사라진다
--   · 상점에서 산 패스 기간은 **프라임이 끝난 뒤부터** 흐른다(구독 중엔 멈춰 있다)

-- 부스트 보유 매수: 출처별 한 행씩. 지금 있는 매수는 어디서 왔는지 알 수 없어 상점 구매분으로 둔다.
ALTER TABLE boost_inventory
    ADD COLUMN source ENUM('PRIME','STORE') NOT NULL DEFAULT 'STORE' AFTER kind,
    DROP PRIMARY KEY,
    ADD PRIMARY KEY (user_id, kind, source);

-- 지금 켜진 부스트가 어느 쪽에서 나갔는지 — 관리 화면의 `이용 중` 표시가 그 칸에 붙는다.
ALTER TABLE boost_activations
    ADD COLUMN source ENUM('PRIME','STORE') NOT NULL DEFAULT 'STORE' AFTER kind;

-- 권리: 루나 구매(LUNA_PURCHASE)는 상점 구매(STORE)가 된다. 출처마다 한 행 — 프라임 기간과 상점 기간을 따로 센다.
-- 상점 구매분은 프라임이 끝난 뒤 시작하므로 started_at이 **미래**일 수 있다(그동안은 혜택 판정에 안 들어간다).
ALTER TABLE user_entitlements
    MODIFY source ENUM('PRIME','LUNA_PURCHASE','STORE') NOT NULL;
UPDATE user_entitlements SET source = 'STORE' WHERE source = 'LUNA_PURCHASE';
ALTER TABLE user_entitlements
    MODIFY source ENUM('PRIME','STORE') NOT NULL,
    DROP PRIMARY KEY,
    ADD PRIMARY KEY (user_id, kind, source);

-- 프라임 부스트를 마지막으로 채운 때 — 30일마다 10개로 다시 채운다(배치).
ALTER TABLE subscriptions
    ADD COLUMN boost_granted_at DATETIME NULL AFTER expires_at;
UPDATE subscriptions SET boost_granted_at = started_at WHERE status IN ('ACTIVE','CANCELLED');
