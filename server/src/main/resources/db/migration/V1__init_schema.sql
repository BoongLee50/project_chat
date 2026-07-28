-- 달빛톡 초기 스키마 (MariaDB 10.4+ 가정: 생성 컬럼 STORED, CHECK 제약 지원)
-- 설계 근거: docs/02-db-schema.md
-- PK/FK는 CHAR(36) UUID 문자열(애플리케이션이 생성해 INSERT). timestamptz는 DATETIME으로 대체(서버 권위 KST, 앱이 시각을 직접 관리).

SET NAMES utf8mb4;

-- ============================================================
-- 1.1 회원 / 프로필
-- ============================================================
CREATE TABLE users (
    id            CHAR(36)     NOT NULL,
    provider      ENUM('LINE','KAKAO','GOOGLE') NOT NULL,
    provider_uid  VARCHAR(191) NOT NULL,
    nickname      VARCHAR(10)  NULL,                 -- 온보딩 전까지 NULL(회원가입 직후 상태)
    birth_year    INT          NULL,
    gender        ENUM('MALE','FEMALE') NULL,
    country       ENUM('KR','JP') NULL,
    status        ENUM('ACTIVE','SUSPENDED','BANNED') NOT NULL DEFAULT 'ACTIVE',
    is_premium    TINYINT(1)   NOT NULL DEFAULT 0,
    premium_until DATETIME     NULL,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_users_provider_uid (provider, provider_uid),
    UNIQUE KEY uk_users_nickname (nickname)           -- NULL은 유니크 검사 제외(다수 허용) — MariaDB 특성
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE user_profiles (
    user_id     CHAR(36)     NOT NULL,
    photo_key   VARCHAR(255) NULL,                   -- 스토리지 key(URL 아님) — 05 문서 §8
    intro       VARCHAR(50)  NULL,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    CONSTRAINT fk_user_profiles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE user_interests (           -- 최대 8개(앱단 검증)
    user_id  CHAR(36)    NOT NULL,
    code     VARCHAR(50) NOT NULL,
    PRIMARY KEY (user_id, code),
    CONSTRAINT fk_user_interests_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE user_regions (             -- 최대 2개(앱단 검증)
    user_id  CHAR(36)    NOT NULL,
    code     VARCHAR(50) NOT NULL,
    PRIMARY KEY (user_id, code),
    CONSTRAINT fk_user_regions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 1.2 루나(재화) — 원장 방식
-- ============================================================
CREATE TABLE luna_wallets (
    user_id  CHAR(36) NOT NULL,
    balance  INT      NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id),
    CONSTRAINT fk_luna_wallets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT ck_luna_wallets_balance CHECK (balance >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE luna_transactions (        -- 증감 이력(원장). reason 값은 구현 시점 확정
    id          CHAR(36)    NOT NULL,
    user_id     CHAR(36)    NOT NULL,
    delta       INT         NOT NULL,
    reason      ENUM('CHARGE','CHAT_REQUEST','REFUND','ADMIN_ADJUST') NOT NULL,
    ref_id      CHAR(36)    NULL,
    created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY ix_luna_transactions_user (user_id, created_at),
    CONSTRAINT fk_luna_transactions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 1.3 포스트 (매일 초기화 — session_date로 구분)
-- ============================================================
CREATE TABLE posts (
    id            CHAR(36)    NOT NULL,
    user_id       CHAR(36)    NOT NULL,
    session_date  DATE        NOT NULL,
    one_liner     VARCHAR(25) NULL,
    published_at  DATETIME    NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_posts_user_session (user_id, session_date),
    CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE post_photos (
    id           CHAR(36)     NOT NULL,
    post_id      CHAR(36)     NOT NULL,
    user_id      CHAR(36)     NOT NULL,
    storage_key  VARCHAR(255) NOT NULL,               -- 다운로드 URL은 저장 안 함(05 문서 §8, 응답 시점에 계산)
    order_idx    INT          NOT NULL DEFAULT 0,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY ix_post_photos_post (post_id, order_idx),
    CONSTRAINT fk_post_photos_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_post_photos_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 1.4 달빛가든 통계 / 스킵 (Redis 비활성 시 집계 원본)
-- ============================================================
CREATE TABLE post_stats (               -- Engage 스코어 계산용 카운터(일자별). Redis 사용 여부와 무관하게 원본
    user_id       CHAR(36) NOT NULL,
    session_date  DATE     NOT NULL,
    exposures     INT      NOT NULL DEFAULT 0,
    likes         INT      NOT NULL DEFAULT 0,
    requests      INT      NOT NULL DEFAULT 0,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, session_date),
    CONSTRAINT fk_post_stats_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE feed_skips (               -- 내가 스킵한 대상(당일 재노출 방지)
    user_id        CHAR(36) NOT NULL,
    target_user_id CHAR(36) NOT NULL,
    session_date   DATE     NOT NULL,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, target_user_id, session_date),
    CONSTRAINT fk_feed_skips_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_feed_skips_target FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 1.5 대화 신청 / 대화방 / 메시지
-- ============================================================
CREATE TABLE chat_requests (
    id          CHAR(36)     NOT NULL,
    from_user   CHAR(36)     NOT NULL,
    to_user     CHAR(36)     NOT NULL,
    message     VARCHAR(100) NOT NULL,
    status      ENUM('PENDING','ACCEPTED','REJECTED','BLOCKED') NOT NULL DEFAULT 'PENDING',
    luna_cost   INT          NOT NULL DEFAULT 0,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY ix_chat_requests_to_user (to_user, status),
    KEY ix_chat_requests_from_user (from_user, status),
    CONSTRAINT fk_chat_requests_from FOREIGN KEY (from_user) REFERENCES users(id),
    CONSTRAINT fk_chat_requests_to FOREIGN KEY (to_user) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE chat_rooms (
    id               CHAR(36)     NOT NULL,
    user_a           CHAR(36)     NOT NULL,
    user_b           CHAR(36)     NOT NULL,
    status           ENUM('ACTIVE','ENDED') NOT NULL DEFAULT 'ACTIVE',
    request_id       CHAR(36)     NULL,
    ended_at         DATETIME     NULL,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- 재매칭 정책(확정): 방 종료는 영구 종료, 재입장 불가 — 재매칭 시 새 row 생성.
    -- 같은 페어의 ACTIVE 방은 동시에 1개만 허용하고 과거 ENDED 방과는 충돌하지 않도록
    -- status=ACTIVE일 때만 값을 갖는 생성 컬럼에 유니크 제약을 건다(NULL은 유니크 검사 제외).
    active_pair_key  VARCHAR(80) GENERATED ALWAYS AS (
                        CASE WHEN status = 'ACTIVE'
                             THEN CONCAT(LEAST(user_a, user_b), '_', GREATEST(user_a, user_b))
                             ELSE NULL END
                      ) STORED,
    PRIMARY KEY (id),
    UNIQUE KEY uk_chat_rooms_active_pair (active_pair_key),
    KEY ix_chat_rooms_user_a (user_a),
    KEY ix_chat_rooms_user_b (user_b),
    CONSTRAINT fk_chat_rooms_user_a FOREIGN KEY (user_a) REFERENCES users(id),
    CONSTRAINT fk_chat_rooms_user_b FOREIGN KEY (user_b) REFERENCES users(id),
    CONSTRAINT fk_chat_rooms_request FOREIGN KEY (request_id) REFERENCES chat_requests(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE chat_messages (            -- 서버 30일 보관(영속). 진행중 캐시는 Redis(선택)
    id          CHAR(36)     NOT NULL,
    room_id     CHAR(36)     NOT NULL,
    sender_id   CHAR(36)     NOT NULL,
    body        VARCHAR(25)  NOT NULL,
    created_at  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),  -- 보관 만료(30일) 판정 기준
    read_at     DATETIME     NULL,
    PRIMARY KEY (id),
    KEY ix_chat_messages_room_created (room_id, created_at),
    KEY ix_chat_messages_created (created_at),                        -- 30일 FIFO 배치 삭제용
    CONSTRAINT fk_chat_messages_room FOREIGN KEY (room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE,
    CONSTRAINT fk_chat_messages_sender FOREIGN KEY (sender_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 1.6 친구 / 신고 / 차단
-- ============================================================
CREATE TABLE friendships (              -- 상대 수락 불필요(단방향 등록)
    id             CHAR(36) NOT NULL,
    user_id        CHAR(36) NOT NULL,
    friend_user_id CHAR(36) NOT NULL,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_friendships_pair (user_id, friend_user_id),
    CONSTRAINT fk_friendships_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_friendships_friend FOREIGN KEY (friend_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE reports (
    id          CHAR(36)     NOT NULL,
    reporter_id CHAR(36)     NOT NULL,
    target_id   CHAR(36)     NOT NULL,
    reason      VARCHAR(500) NOT NULL,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY ix_reports_target (target_id),
    CONSTRAINT fk_reports_reporter FOREIGN KEY (reporter_id) REFERENCES users(id),
    CONSTRAINT fk_reports_target FOREIGN KEY (target_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE blocks (
    id          CHAR(36) NOT NULL,
    blocker_id  CHAR(36) NOT NULL,
    blocked_id  CHAR(36) NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_blocks_pair (blocker_id, blocked_id),
    CONSTRAINT fk_blocks_blocker FOREIGN KEY (blocker_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_blocks_blocked FOREIGN KEY (blocked_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
