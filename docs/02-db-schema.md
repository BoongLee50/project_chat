# 달빛톡 — 데이터 스키마 설계 (초안)

> 상태: **설계 초안**. PostgreSQL(영속) + Redis(휘발/랭킹/프레즌스) + Object Storage(사진) 분리.
> 원칙: 매일 초기화·랭킹·프레즌스처럼 휘발성/고빈도 데이터는 Redis, 회원·원장·신고 등 영속 데이터는 PostgreSQL.

---

## 1. PostgreSQL (영속)

### 1.1 회원 / 프로필
```
users
  id            uuid  PK
  provider      enum(LINE, KAKAO, GOOGLE)
  provider_uid  text                      -- 소셜 고유 ID
  nickname      varchar(10) unique
  birth_year    int                       -- 만 18세 이상 검증
  gender        enum(MALE, FEMALE)
  country       enum(KR, JP)
  status        enum(ACTIVE, SUSPENDED, BANNED) default ACTIVE
  is_premium    bool default false
  premium_until timestamptz null
  created_at    timestamptz
  UNIQUE(provider, provider_uid)

user_profiles
  user_id     uuid PK/FK -> users
  photo_url   text null                    -- 프로필 사진 1장
  intro       varchar(50) null             -- 소개 한마디
  updated_at  timestamptz

user_interests            -- 최대 8 (앱단/트리거 제약)
  user_id  uuid FK
  code     text                            -- 관심사 코드
  PK(user_id, code)

user_regions              -- 최대 2
  user_id  uuid FK
  code     text                            -- 지역 코드
  PK(user_id, code)
```

### 1.2 루나(재화) — 원장 방식
```
luna_wallets
  user_id  uuid PK/FK
  balance  int default 0

luna_transactions        -- 증감 이력(원장). 잔액은 wallets, 변동은 여기
  id          uuid PK
  user_id     uuid FK
  delta       int                          -- +충전 / -소비(대화신청 -5)
  reason      enum(CHARGE, CHAT_REQUEST, REFUND, ...)
  ref_id      uuid null                     -- 관련 엔티티(chat_request 등)
  created_at  timestamptz
```
> 대화신청 시 `wallets.balance` 차감과 `transactions` 기록을 **단일 트랜잭션**으로. 잔액 부족은 애플리케이션에서 원자적 검증.

### 1.3 포스트 (매일 초기화 — session_date로 구분)
```
posts
  id            uuid PK
  user_id       uuid FK
  session_date  date                        -- KST 영업일(06시 기준). 초기화 배치가 이 값으로 정리
  one_liner     varchar(25) null            -- 하루 한마디
  published_at  timestamptz null            -- 공유하기 시점
  UNIQUE(user_id, session_date)

post_photos
  id           uuid PK
  post_id      uuid FK -> posts
  user_id      uuid FK
  storage_key  text                         -- S3 key
  url          text                         -- CDN URL
  order_idx    int                          -- 노출 순서(터치 순환)
  created_at   timestamptz
```
> 06시 초기화 배치: 지난 `session_date` posts/photos 제거(+Storage 정리) 또는 아카이브.

### 1.4 대화 신청 / 대화방 / 메시지
```
chat_requests
  id          uuid PK
  from_user   uuid FK
  to_user     uuid FK
  message     varchar(100)
  status      enum(PENDING, ACCEPTED, REJECTED, BLOCKED)
  luna_cost   int
  created_at  timestamptz

chat_rooms
  id          uuid PK
  user_a      uuid FK
  user_b      uuid FK
  status      enum(ACTIVE, ENDED)
  request_id  uuid FK null -> chat_requests
  ended_at    timestamptz null             -- 종료 30분 후 삭제 배치 기준
  created_at  timestamptz
  UNIQUE(user_a, user_b)                    -- 정렬된 페어로 중복 방지

chat_messages                              -- 서버 30일 보관(영속). 진행중은 Redis 캐시
  id          uuid PK
  room_id     uuid FK
  sender_id   uuid FK
  body        varchar(25)
  created_at  timestamptz                    -- 보관 만료(30일) 판정 기준
  read_at     timestamptz null
```
> **보관정책(확정)**: 서버는 메시지를 **30일간 보관**하고, 30일이 지난 것부터 **오래된 순(앞에서부터) 삭제 = 큐(FIFO)**. 클라이언트의 "대화 삭제"는 **UI 표시만 제거**(서버 데이터는 30일 큐가 만료시킬 때까지 유지). 구현: `created_at < now() - 30일` 메시지를 일배치로 삭제(오래된 것부터). 방 목록에서의 종료 항목 제거(`ended_at + 30분`)는 별개(기획서 5장).

### 1.5 친구 / 신고 / 차단
```
friendships               -- 상대 수락 불필요(단방향 등록)
  id             uuid PK
  user_id        uuid FK
  friend_user_id uuid FK
  created_at     timestamptz
  UNIQUE(user_id, friend_user_id)

reports
  id          uuid PK
  reporter_id uuid FK
  target_id   uuid FK
  reason      text
  created_at  timestamptz

blocks
  id          uuid PK
  blocker_id  uuid FK
  blocked_id  uuid FK
  created_at  timestamptz
  UNIQUE(blocker_id, blocked_id)
```
> 신고·차단 발생 시: 친구 관계 즉시 삭제, 상대의 내 프로필 열람 차단, 대화방 종료.

---

## 2. Redis (휘발 / 랭킹 / 실시간)

| 키 패턴 | 타입 | 용도 | TTL |
|---------|------|------|-----|
| `presence:{userId}` | string | 온라인 표시(heartbeat 갱신) | 짧게(예 60s) |
| `feed:score:{date}` | ZSET | 달빛가든 노출 랭킹(userId→score) | 영업일 종료 |
| `feed:score:premium:{date}` | ZSET | 스포트라이트 전용 랭킹 | 영업일 종료 |
| `post:stats:{userId}:{date}` | HASH | likes / exposures / requests(전환율 계산) | 영업일 종료 |
| `feed:skip:{userId}:{date}` | SET | 내가 스킵한 대상 | 영업일 종료 |
| `unread:{userId}` | HASH | roomId→미확인 수 | - |
| `chat:room:{roomId}:recent` | LIST | 진행중 메시지 캐시 | 활성 동안 |
| `system:gate` | string | 현재 오픈 상태 캐시 | 배치 갱신 |

> Post Score는 like/skip/노출 이벤트마다 `feed:score:{date}` ZSET을 갱신하여 실시간 정렬. 앱 종료(05시) 시 스코어 관련 키 초기화.

---

## 3. Object Storage + CDN
- 버킷: 포스트 사진 / 프로필 사진 분리. key 예: `posts/{userId}/{date}/{uuid}.jpg`
- 업로드: 클라 → presigned URL로 **직접 업로드**(서버·소켓 미경유) → 완료 후 REST로 메타 등록.
- 서빙: CDN URL. 만료/초기화된 포스트 사진은 정리 배치로 삭제.

---

## 4. 스케줄러(배치)가 건드리는 데이터
- **18:00** `system:gate` 오픈 / **05:00** 종료 처리 + `SYSTEM_CLOSE` 브로드캐스트
- **06:00** 지난 영업일 posts/post_photos + Storage + score 키 초기화
- **상시** `ended_at+30분` 대화방/메시지 정리, presence TTL 자연 만료
