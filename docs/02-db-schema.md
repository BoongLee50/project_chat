# 달빛톡 — 데이터 스키마 설계 (초안)

> 상태: **설계 확정**. Spring Boot + MariaDB(MyBatis, 영속) + Redis(휘발/랭킹/프레즌스, 선택 구성) + Object Storage(사진) 분리.
> 원칙: 매일 초기화·랭킹·프레즌스처럼 휘발성/고빈도 데이터는 Redis(선택), 회원·원장·신고·대화 등 영속 데이터는 MariaDB.
> Redis는 `app.redis.enabled` 설정으로 on/off. 비활성화 시 프레즌스=인메모리, 피드 스코어=MariaDB 직접 집계, 최근 메시지 캐시=생략(DB 조회), 미확인 수=DB 카운트 쿼리로 대체 — 단일 인스턴스 운영에는 지장 없음(수평 확장 시에는 Redis 필요).

---

## 1. MariaDB (영속, MyBatis)

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
  photo_key   text null                    -- 프로필 사진 1장의 스토리지 key(URL 아님 — post_photos와 동일하게 응답 시점에 다운로드 URL 계산)
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
> 대화신청 시 `wallets.balance` 차감과 `transactions` 기록을 **단일 트랜잭션**으로. 동시 요청으로 인한 잔액 음수 방지를 위해 차감 전 `SELECT balance FROM luna_wallets WHERE user_id=? FOR UPDATE`로 **비관적 락**을 건 뒤 잔액 검증 → 차감 → 원장 insert 순서로 처리. Mapper 설계는 [05 서버구조 §3](05-server-structure.md#3-mybatis-구성) 참고.

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
  storage_key  text                         -- 스토리지 key(S3 key 또는 로컬 파일 경로 — 05 문서 §8)
  order_idx    int                          -- 노출 순서(터치 순환)
  created_at   timestamptz
```
> 06시 초기화 배치: 지난 `session_date` posts/photos 제거(+Storage 정리) 또는 아카이브.
> 다운로드 URL은 저장하지 않음 — 조회 응답을 만들 때마다 `storage_key`로 `FileStorageService.issueDownloadUrl()`을 호출해 즉시 계산(S3는 presigned URL이 TTL로 만료되므로 저장해봐야 금방 stale해짐, 로컬도 매번 동일 규칙으로 계산 가능해 저장할 이유가 없음). 상세: [05 서버구조 §8](05-server-structure.md#8-파일-스토리지-추상화-s3--로컬-디스크).

### 1.4 달빛가든 통계 / 스킵 (영속 — Redis 비활성 시 집계 원본)
```
post_stats                                 -- Engage 스코어 계산용 카운터(일자별). Redis 사용 여부와 무관하게 원본(source of truth)
  user_id       uuid FK
  session_date  date
  exposures     int default 0              -- 노출 수
  likes         int default 0              -- 좋아요 수
  requests      int default 0              -- 대화 신청(전환) 수
  updated_at    timestamptz
  PK(user_id, session_date)

feed_skips                                 -- 내가 스킵한 대상(당일 재노출 방지)
  user_id        uuid FK                    -- 스킵한 사람
  target_user_id uuid FK                    -- 스킵당한 사람
  session_date   date
  created_at     timestamptz
  PK(user_id, target_user_id, session_date)
```
> 노출/좋아요/신청/스킵 이벤트 발생 시 **항상 이 테이블을 먼저 갱신**. Redis 활성화 시에는 추가로 `feed:score:{date}` ZSET 등도 갱신해 빠른 정렬용 캐시로 사용(§2). Redis 비활성화 시엔 이 두 테이블을 직접 집계해 Post Score를 계산.
> **동시성**: `post_stats` 갱신은 읽고-더하고-쓰기가 아니라 `INSERT ... ON DUPLICATE KEY UPDATE exposures = exposures + 1`(해당 컬럼만) 같은 원자적 UPSERT로 처리(동시 좋아요/노출 시 lost update 방지). `feed_skips`는 같은 대상을 중복 스킵해도 에러 안 나게 `INSERT IGNORE`로 처리.
> **정리**: 06시 초기화 배치(§4)가 지난 `session_date`의 `post_stats`/`feed_skips`도 함께 정리 대상에 포함(무한정 누적 방지).

### 1.5 대화 신청 / 대화방 / 메시지
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
  id               uuid PK
  user_a           uuid FK
  user_b           uuid FK
  status           enum(ACTIVE, ENDED)
  request_id       uuid FK null -> chat_requests
  ended_at         timestamptz null             -- 종료 30분 후 삭제 배치 기준
  created_at       timestamptz
  active_pair_key  varchar(80) GENERATED ALWAYS AS (
                      CASE WHEN status = 'ACTIVE'
                           THEN CONCAT(LEAST(user_a, user_b), '_', GREATEST(user_a, user_b))
                           ELSE NULL END
                    ) STORED
  UNIQUE(active_pair_key)                       -- 같은 페어의 ACTIVE 방은 동시에 1개만. ENDED는 NULL이라 유니크 검사 제외 → 과거 방과 충돌 없이 여러 개 허용

chat_messages                              -- 서버 30일 보관(영속). 진행중은 Redis 캐시(선택, 비활성 시 DB 직접 조회)
  id          uuid PK
  room_id     uuid FK
  sender_id   uuid FK
  body        varchar(25)
  created_at  timestamptz                    -- 보관 만료(30일) 판정 기준
  read_at     timestamptz null
```
> **보관정책(확정)**: 서버는 메시지를 **30일간 보관**하고, 30일이 지난 것부터 **오래된 순(앞에서부터) 삭제 = 큐(FIFO)**. 클라이언트의 "대화 삭제"는 **UI 표시만 제거**(서버 데이터는 30일 큐가 만료시킬 때까지 유지). 구현: `created_at < now() - 30일` 메시지를 일배치로 삭제(오래된 것부터). 방 목록에서의 종료 항목 제거(`ended_at + 30분`)는 별개(기획서 5장).
> **재매칭 정책(확정)**: 방이 `ENDED`되면 그 방은 **영구 종료 — 재입장/재활성화 불가**. 같은 두 사람이 이후 다시 매칭되면 완전히 새로운 `chat_rooms` row(새 id)가 생성되고, 예전 방은 이력으로만 남음(메시지도 그대로 30일 보관 정책을 따름). `active_pair_key`는 `ACTIVE` 상태일 때만 값을 가지므로, 동시에 두 개의 ACTIVE 방이 같은 페어로 생기는 것만 막고 과거 ENDED 방과는 유니크 충돌이 없음(MySQL/MariaDB 유니크 인덱스가 NULL을 여러 개 허용하는 특성을 이용한 "부분 유니크 인덱스" 트릭).

### 1.6 친구 / 신고 / 차단
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

## 2. Redis (휘발 / 랭킹 / 실시간) — 선택 구성

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

> Post Score는 like/skip/노출 이벤트마다 §1.4 `post_stats`/`feed_skips`(MariaDB, source of truth) 갱신 + Redis 활성화 시 `feed:score:{date}` ZSET도 함께 갱신해 실시간 정렬에 사용. 앱 종료(05시) 시 스코어 관련 Redis 키 초기화(MariaDB 카운터는 06시 배치가 정리).
> **Redis 비활성화 시 대체**: `presence:*` → 인메모리 Map(단일 인스턴스 기준), `feed:score:*`/`post:stats:*`/`feed:skip:*` → §1.4 `post_stats`/`feed_skips`를 직접 집계, `chat:room:*:recent` → 생략하고 `chat_messages` 직접 조회, `unread:*` → `chat_messages.read_at` 기반 COUNT 쿼리로 대체.

---

## 3. 파일 스토리지 (S3 또는 로컬 디스크 — 설정으로 전환)
- 버킷/디렉터리: 포스트 사진 / 프로필 사진 분리. key 예: `posts/{userId}/{date}/{uuid}.jpg`(슬래시 포함 — API에서는 경로 변수가 아니라 쿼리 파라미터로 전달, 05 §8 참고).
- 업로드: 클라 → 업로드 URL 발급 API 호출 → 그 URL로 **직접 업로드**. S3 모드는 presigned URL(서버·소켓 미경유), 로컬 모드는 서버 자체 업로드 엔드포인트(`PUT /internal/files?key=`) — 클라이언트 입장에서는 동일한 흐름. 완료 후 REST로 메타 등록.
- 다운로드: 목록/상세 조회 API 응답에 다운로드 URL이 이미 포함되어 내려옴(이미지마다 별도 인증 호출 불필요). S3 모드=presigned GET URL로 S3/CDN이 직접 서빙, 로컬 모드=인증이 걸린 `GET /files?key=` 컨트롤러가 직접 스트리밍(정적 리소스 핸들러 아님). 만료/초기화된 포스트 사진은 정리 배치로 삭제.
- 구현 상세(추상화 인터페이스·설정 키): [05 서버구조 §8](05-server-structure.md#8-파일-스토리지-추상화-s3--로컬-디스크) 참고.

---

## 4. 스케줄러(배치)가 건드리는 데이터
- **18:00** `system:gate` 오픈 / **05:00** 종료 처리 + `SYSTEM_CLOSE` 브로드캐스트
- **06:00** 지난 영업일 posts/post_photos + post_stats/feed_skips + Storage + score 키 초기화
- **상시** `ended_at+30분` 대화방/메시지 정리, presence TTL 자연 만료
