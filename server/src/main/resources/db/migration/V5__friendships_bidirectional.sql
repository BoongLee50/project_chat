-- 친구 = 양방향(상호 동의)으로 전환. (02 문서 §1.6)
--
-- V1의 friendships는 "상대 수락 불필요(단방향 등록)" 설계였다. Plan_2 확정 사항은
-- 요청 → 상대 수락이므로 컬럼 구성 자체가 달라진다. 친구 기능은 아직 한 번도
-- 동작한 적이 없어 이 테이블은 항상 비어 있다 → 그대로 재생성한다.
--
-- pair_key는 두 사람의 관계를 방향과 무관하게 1건으로 묶는 키다.
-- MariaDB 11.4는 생성 컬럼에서 CONCAT/LEAST/GREATEST를 허용하지 않으므로(err 1901)
-- 일반 컬럼으로 두고 애플리케이션이 채운다. (07 문서 함정 #2)

DROP TABLE IF EXISTS friendships;

CREATE TABLE friendships (
    id           CHAR(36) NOT NULL,
    requester_id CHAR(36) NOT NULL,               -- 요청한 사람
    addressee_id CHAR(36) NOT NULL,               -- 수락해야 하는 사람
    status       ENUM('PENDING','ACCEPTED') NOT NULL DEFAULT 'PENDING',
    pair_key     VARCHAR(80) NOT NULL,            -- CONCAT(LEAST(a,b),'_',GREATEST(a,b))
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at  DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_friendships_pair (pair_key),    -- 같은 두 사람 관계는 1건
    KEY ix_friendships_addressee (addressee_id, status),
    KEY ix_friendships_requester (requester_id, status),
    CONSTRAINT fk_friendships_requester FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_friendships_addressee FOREIGN KEY (addressee_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
