-- BM(유료 상점/구독/엔티틀먼트/부스트) 엔티티. (02 문서 §1.7, 01 문서 §1.8)
--
-- 원칙: 가격·상품 구성은 여기 두지 않는다. 이 테이블들은 "누가 무엇을 언제까지 쓸 수 있는가"라는
-- 상태만 저장하고, 가격/구성은 설정(app.store.*)에서 온다 — BM 값이 바뀌어도 스키마를 안 건드리게.
--
-- daily_usage(일일 무료 쿼터)는 V4에서 이미 만들었다.

-- ── 프라임 멤버십(구독) ───────────────────────────────────
-- 같은 사용자의 ACTIVE 구독은 1개만. MariaDB는 부분 유니크 인덱스가 없어
-- chat_rooms.active_pair_key와 같은 트릭을 쓴다(ACTIVE일 때만 값, 아니면 NULL → 유니크 검사 제외).
CREATE TABLE subscriptions (
    id             CHAR(36) NOT NULL,
    user_id        CHAR(36) NOT NULL,
    product        ENUM('PRIME_1M','PRIME_6M') NOT NULL,
    status         ENUM('ACTIVE','CANCELLED','EXPIRED') NOT NULL DEFAULT 'ACTIVE',
    started_at     DATETIME NOT NULL,
    expires_at     DATETIME NOT NULL,
    auto_renew     TINYINT(1) NOT NULL DEFAULT 1,   -- CANCELLED = 자동갱신만 해지(만료까지 유효)
    store_txn      VARCHAR(255) NULL,               -- 인앱결제 참조
    active_user_id CHAR(36) NULL,                   -- ACTIVE일 때만 user_id, 아니면 NULL
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_subscriptions_active (active_user_id),
    KEY ix_subscriptions_user (user_id, expires_at),
    KEY ix_subscriptions_expiry (status, expires_at),
    CONSTRAINT fk_subscriptions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 시간제 권리(앨범패스/번역패스/대화무제한/광고제거) ────
-- 02 문서는 id를 PK로 그렸으나 "같은 kind 활성 1개, 연장 시 expires_at 갱신"이라는
-- 제약을 구조로 보장하려면 (user_id, kind)가 PK인 편이 낫다 → UPSERT로 연장한다.
CREATE TABLE user_entitlements (
    user_id    CHAR(36) NOT NULL,
    kind       ENUM('ALBUM_PASS','TRANSLATE_PASS','UNLIMITED_CHAT_REQ','NO_ADS') NOT NULL,
    source     ENUM('PRIME','LUNA_PURCHASE') NOT NULL,
    started_at DATETIME NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, kind),
    KEY ix_entitlements_expiry (expires_at),
    CONSTRAINT fk_entitlements_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 부스트 보유 매수 ──────────────────────────────────────
CREATE TABLE boost_inventory (
    user_id  CHAR(36) NOT NULL,
    kind     ENUM('POST_BOOST','SPOTLIGHT_BOOST') NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, kind),
    CONSTRAINT fk_boost_inventory_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 부스트 사용(1시간) → Post Score의 Pick Point 반영 ────
CREATE TABLE boost_activations (
    id           CHAR(36) NOT NULL,
    user_id      CHAR(36) NOT NULL,
    kind         ENUM('POST_BOOST','SPOTLIGHT_BOOST') NOT NULL,
    session_date DATE NOT NULL,
    started_at   DATETIME NOT NULL,
    expires_at   DATETIME NOT NULL,               -- started_at + 1시간
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY ix_boost_activations_user (user_id, expires_at),
    KEY ix_boost_activations_expiry (expires_at),
    CONSTRAINT fk_boost_activations_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 인앱결제 영수증(멱등) ────────────────────────────────
-- 01 문서 §1.8이 요구하는 "purchaseToken 저장 → 중복 지급 방지"의 저장소.
-- 같은 토큰으로 다시 들어오면 유니크 위반이 나므로 지급이 두 번 되지 않는다.
CREATE TABLE store_purchases (
    id             CHAR(36) NOT NULL,
    user_id        CHAR(36) NOT NULL,
    platform       ENUM('GOOGLE','APPLE') NOT NULL,
    product_id     VARCHAR(191) NOT NULL,
    purchase_token VARCHAR(512) NOT NULL,
    token_hash     CHAR(64) NOT NULL,             -- purchase_token은 길어 인덱스가 안 걸린다 → SHA-256으로 유니크
    status         ENUM('GRANTED','REFUNDED') NOT NULL DEFAULT 'GRANTED',
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_store_purchases_token (platform, token_hash),
    KEY ix_store_purchases_user (user_id, created_at),
    CONSTRAINT fk_store_purchases_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 루나 원장 사유 확장 ──────────────────────────────────
ALTER TABLE luna_transactions
    MODIFY COLUMN reason ENUM(
        'CHARGE','CHAT_REQUEST','REFUND','ADMIN_ADJUST',
        'BUY_BOOST','BUY_ALBUM_PASS','BUY_TRANSLATE_PASS'
    ) NOT NULL;
