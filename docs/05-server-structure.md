# 달빛톡 — 서버(Spring Boot) 구조 설계 (초안)

> 상태: **설계 초안**(코드 아님). 스택 확정: Spring Boot + MariaDB(MyBatis) + Redis(선택 구성). [01 프로토콜/API](01-protocol-api-spec.md) · [02 DB 스키마](02-db-schema.md) 참고.
> 레포 구성: **모노레포**. 클라이언트(`lib/`)와 서버(`server/`)를 한 저장소에서 함께 관리 — `docs/`가 이미 양쪽 설계를 함께 다루고 있어 계약(API 스펙) 동기화가 쉬움.
> **Plan_2 반영 필요(2026-07-30)**: ① 신규 `store`(결제·구독·부스트·패스=BM) 도메인 추가 — [01 §1.8](01-protocol-api-spec.md) / [02 §1.7](02-db-schema.md). ② `friend` 양방향(요청/수락) + 친구 상시 대화방(`chat_rooms.type=FRIEND`, 야간 게이트·30분 삭제 예외). ③ 운영시간 **17:00~06:00**(§5 스케줄러 값), 일일 무료 쿼터(`daily_usage`). 세부 구조 확정은 서버 개발자 반영 예정.

---

## 1. 폴더 구조 (feature-first)

```
project_chat/                   (레포 루트)
├─ lib/                         # Flutter 클라이언트 (기존)
├─ docs/                        # 설계 문서 (기존)
└─ server/                      # Spring Boot 백엔드 (신규)
   ├─ build.gradle.kts
   ├─ settings.gradle.kts
   ├─ src/main/java/com/moonlighttalk/server/
   │  ├─ ServerApplication.java
   │  ├─ common/                # 앱 전역 공통(도메인 무관)
   │  │  ├─ config/             # WebMvcConfig(CORS+인터셉터 등록), RedisConfig, WebSocketConfig, SchedulerConfig, MyBatisConfig
   │  │  ├─ security/           # JwtProvider, JwtAuthInterceptor, AuthContext, NoAuth — §11 (Spring Security 미사용)
   │  │  ├─ exception/          # GlobalExceptionHandler, 커스텀 예외
   │  │  ├─ response/           # ApiResponse 래퍼, ErrorCode
   │  │  └─ storage/            # FileStorageService(S3/로컬 디스크 추상화) — §8
   │  ├─ auth/                  # 소셜 로그인, 토큰 발급/갱신, 시간 게이트
   │  │  └─ social/             # SocialAuthProvider 구현(LINE/KAKAO/GOOGLE, 설정 기반 enabled) — §9.1
   │  ├─ profile/                # 온보딩/프로필(닉네임·관심사·지역·소개)
   │  ├─ post/                   # 오늘의 포스트(사진·하루 한마디)
   │  ├─ garden/                 # 달빛가든 피드/댓글/번역/Post Score
   │  │  └─ translate/          # TranslationProvider 추상화(Passthrough/실제 API) — §9
   │  ├─ chat/                   # 대화 신청 + 대화방 REST + WebSocket
   │  │  ├─ controller/
   │  │  ├─ service/
   │  │  ├─ mapper/              # MyBatis 인터페이스
   │  │  ├─ socket/              # WS 핸들러, opcode 라우팅
   │  │  └─ dto/
   │  ├─ friend/                 # 친구 목록/등록/삭제
   │  ├─ moderation/             # 신고/차단
   │  ├─ luna/                   # 재화(원장) 잔액/충전/차감
   │  ├─ presence/                # 온라인 상태 (Redis 선택 구성)
   │  └─ scheduler/               # 17/06시 배치, 지난 영업일 정리 (30일 FIFO는 2차)
   ├─ src/main/resources/
   │  ├─ application.yml          # 공통 설정 (+ -local / -dev / -prod 프로필)
   │  ├─ mapper/**/*.xml          # MyBatis SQL, java 패키지와 1:1 대응
   │  └─ db/migration/            # Flyway DDL(버전 관리)
   └─ src/test/java/...
```

각 도메인(feature) 패키지 내부 공통 레이어:
```
chat/
├─ controller/   # REST 엔드포인트 (요청 검증 → service 위임)
├─ service/      # 트랜잭션/비즈니스 로직
├─ mapper/       # MyBatis Mapper 인터페이스 (SQL은 resources/mapper/에 분리)
├─ socket/       # (해당 도메인만) WebSocket opcode 핸들러
└─ dto/          # 요청/응답 DTO
```

**레이어가 아닌 도메인 기준으로 패키지를 나눈 이유**: Flutter 쪽 feature-first 구조, `01-protocol-api-spec.md`의 도메인 구분(인증/프로필/포스트/가든/채팅/친구/모더레이션/루나)과 그대로 대응돼서 API 하나를 수정할 때 관련 파일을 한 폴더에서 찾을 수 있음. 전통적인 레이어드(controller 전체를 한 곳에 모으는) 구조보다 이 프로젝트 규모(1인/소규모)에 적합.

---

## 2. Redis 선택 구성 (설정으로 on/off)

`presence`, 피드 스코어 캐시, 멀티 노드 소켓 브로드캐스트처럼 Redis를 쓰는 기능은 **인터페이스로 추상화**하고, `application.yml`의 `app.redis.enabled` 값에 따라 구현체를 스위칭한다.

```
presence/
├─ PresenceService.java              # interface
├─ RedisPresenceServiceImpl.java     # @ConditionalOnProperty(name="app.redis.enabled", havingValue="true")
└─ InMemoryPresenceServiceImpl.java  # @ConditionalOnProperty(..., havingValue="false", matchIfMissing=true)
```

| 기능 | Redis 활성화 | Redis 비활성화(대체) |
|------|-------------|---------------------|
| 프레즌스(`presence:{userId}`) | Redis string + TTL | 인메모리 `ConcurrentHashMap` |
| 피드 스코어(`feed:score:{date}`) | Redis ZSET 실시간 갱신 | MariaDB에서 즉시 집계 쿼리 |
| 최근 메시지 캐시(`chat:room:*:recent`) | Redis LIST | 생략, `chat_messages` 직접 조회 |
| 미확인 수(`unread:*`) | Redis HASH | `chat_messages.read_at` 기반 COUNT 쿼리 |
| 멀티 노드 소켓 브로드캐스트 | Redis Pub/Sub | 단일 인스턴스 한정 동작(다중 인스턴스 시 필요) |

> 단일 인스턴스 운영에는 Redis 없이도 서비스 지장 없음. 서버를 여러 대로 수평 확장할 때만 Redis(Pub/Sub)가 사실상 필요해짐.

---

## 3. MyBatis 구성

- Mapper 인터페이스(`xxx/mapper/XxxMapper.java`)는 도메인 패키지 안에, 매핑 XML(`resources/mapper/xxx/XxxMapper.xml`)은 동일한 상대 경로로 분리 — 패키지 구조와 리소스 경로를 1:1 대응시켜 탐색 용이.
- 복잡한 조회(Post Score 정렬, 커서 페이징, FIFO 30일 삭제 대상 조회)는 MyBatis로 SQL을 직접 튜닝.
- 단순 CRUD도 Mapper XML을 명시적으로 작성(JPA의 자동 매핑 없음) — 보일러플레이트는 늘지만 쿼리 동작이 명확함.
- **루나 차감 동시성**: `LunaMapper`에 비관적 락 조회를 별도 정의 — `selectBalanceForUpdate(userId)` → `SELECT balance FROM luna_wallets WHERE user_id=#{userId} FOR UPDATE`. `LunaService.deduct()`가 `@Transactional` 안에서 이 조회로 락을 잡은 뒤 잔액 검증 → 차감 → `luna_transactions` insert 순서로 처리해 동시 대화 신청 시 잔액이 음수로 빠지는 레이스 컨디션을 방지.
- **대화방 재매칭**: `ChatRoomMapper.insertRoom()`은 대화 신청 수락 시 **항상 새 row를 INSERT**(기존 ENDED 방을 재사용/업데이트하지 않음). `chat_rooms.active_pair_key` 유니크 제약(02 문서 §1.5)에 걸리면 "이미 같은 상대와 진행 중인 방이 있음" 상황이므로, `DataIntegrityViolationException`을 잡아 `ROOM_ALREADY_ACTIVE`류 에러로 변환해 응답.

---

## 4. WebSocket 구조

- `common/config/WebSocketConfig`에서 엔드포인트/핸들러 등록.
- 봉투 형식 `{ op, seq, ts, data }`([01](01-protocol-api-spec.md#21-봉투envelope) 참고)를 그대로 사용하는 **커스텀 핸들러 방식**(STOMP 프레임 대신 raw WebSocket + JSON 봉투) — 클라 `packet.dart`/`opcodes.dart` 설계와 1:1 대응.
- `chat/socket/`에서 opcode별 핸들러 분기(`AUTH`, `CHAT_SEND`, `ROOM_SUBSCRIBE`, `CHAT_READ` 등). 인증은 연결 직후 `AUTH` 패킷으로 별도 처리(HTTP 인터셉터와 분리).
- 세션-유저 매핑은 인메모리(단일 인스턴스) 또는 Redis(다중 인스턴스, 선택)로 관리.

---

## 5. 스케줄러(배치)

`scheduler/`에 `@Scheduled` 기반 배치 정의, [02 스키마 §4](02-db-schema.md#4-스케줄러배치가-건드리는-데이터)와 대응:

> 시각은 **Plan_2 기준 17:00 개방 / 06:00 종료**(KST). 아래 표의 cron은 `app.scheduler.*`로 설정하며
> **`app.gate.open-hour`/`close-hour`와 같은 값이어야 한다**(게이트 판정과 배치 시각이 두 곳에 있음).

| 시각/주기 | 작업 | 상태 |
|-----------|------|------|
| 17:00 | 서비스 개방(게이트 판정은 시간 계산이라 상태 변경 없음 — 기록만) | ✅ |
| 06:00 | 매칭 대화방 일괄 종료 + `ROOM_STATE(ended)` · `SYSTEM_CLOSE` 브로드캐스트. **친구 방(`type=FRIEND`)은 제외** | ✅ |
| 06:05 | 지난 영업일 `post_photos`(+Storage 파일) / `post_stats` / `feed_skips` / `daily_usage` 삭제, `posts`는 **사용자별 최신 1건만 남기고** 삭제 | ✅ |
| 5분 | presence 인메모리 만료 항목 청소(Redis 비활성 시 필요 — Redis면 TTL이 처리) | ✅ |
| 상시 | `chat_messages` 30일 초과분 FIFO 삭제 | ⏸ 2차(친구 방 적용 여부 미결) |
| 상시 | 만료된 `boost_activations`/`user_entitlements` 정리, 구독 갱신·만료 | ⏸ 2차(BM 테이블 미생성) |

**왜 posts를 다 지우지 않는가**: 하루 한 마디(`posts.one_liner`)가 이 row에 있고 다음 영업일 첫 진입 때 값을 이어받는다. 전부 지우면 "하루 한 마디는 유지"(기획서 3-1)가 깨지므로 **사용자별 최신 1건은 남긴다**.

**개발용 수동 실행**: `app.scheduler.dev-trigger-enabled=true`(local 프로필만)일 때
`POST /internal/scheduler/gate-close`, `POST /internal/scheduler/daily-cleanup`으로 06시를 기다리지 않고 확인할 수 있다.

---

## 6. 추천 의존성 (Gradle 예정 — 아직 설치 X)

| 용도 | 라이브러리 |
|------|-----------|
| 웹/REST | `spring-boot-starter-web` |
| WebSocket | `spring-boot-starter-websocket` |
| 인증 | `jjwt`(JWT 생성/검증) — **`spring-boot-starter-security`는 사용하지 않음**(§11) |
| DB | `mybatis-spring-boot-starter`, `mariadb-java-client` |
| 마이그레이션 | `flyway-core` (+ `flyway-mysql`) |
| Redis(선택) | `spring-boot-starter-data-redis`(Lettuce) |
| Object Storage(선택, S3 모드) | `software.amazon.awssdk:s3` |
| 스케줄러 | `spring-boot-starter` 내장 `@Scheduled` (+ `@EnableScheduling`) |
| 검증 | `spring-boot-starter-validation` |
| 테스트 | `spring-boot-starter-test`, `testcontainers`(MariaDB/Redis) |

> 설치는 실제 구현 단계에서. 지금은 구조/선택만 확정.

---

## 7. application.yml 프로필 메모

- `application.yml`(공통) + `application-local.yml` / `application-dev.yml` / `application-prod.yml` 3단 분리.
- 활성화: 실행 시 `SPRING_PROFILES_ACTIVE=local|dev|prod` 환경변수(또는 `-Dspring.profiles.active=`)로 지정. 기본값은 `local`.
- 주요 커스텀 프로퍼티 예: `app.redis.enabled`, `app.jwt.secret`, `app.gate.open-hour`(18) / `app.gate.close-hour`(05), `app.storage.type`(local/s3) + `app.storage.bucket`, `app.auth.social.{line|kakao|google}.enabled` + `client-id`/`client-secret`/`verify-url`, `app.translate.provider`(none/실제 공급자).

| 구분 | local | dev | prod |
|------|-------|-----|------|
| 용도 | 개발자 로컬 PC | 통합/QA 서버(공유) | 운영 |
| MariaDB/Redis | Docker Compose로 로컬 기동 | 개발용 공유 인스턴스(RDS/VM 등) | 운영 인스턴스(이중화·백업 적용) |
| `app.redis.enabled` | `false`(기본, 필요 시 로컬 Redis 켜서 검증) | `true` | `true` |
| 시크릿(JWT/DB/소셜 키) | `application-local.yml`에 더미값 하드코딩 가능 | 환경변수/시크릿 매니저 주입 | 환경변수/시크릿 매니저 주입(필수, 커밋 금지) |
| 로깅 레벨 | DEBUG | INFO(필요 시 특정 패키지만 DEBUG) | INFO/WARN |
| DDL 관리 | Flyway 자동 실행 허용 | Flyway 자동 실행 | Flyway는 배포 파이프라인에서만 실행(수동 승인) |
| `app.storage.type` | `local`(`server/uploads/`) | `local` 또는 `s3`(연동 검증용) | `s3` |
| `app.auth.social.*.enabled` | 키 발급된 provider만 `true`(나머진 `false`) | 키 발급된 provider만 `true` | 키 발급된 provider만 `true` |
| `app.translate.provider` | `none`(패스스루) | `none` 또는 실제 공급자 | 실제 공급자(발급 후 전환) |
| CORS | 전체 허용 | 전체 허용 | 전체 허용(추후 웹 서빙 도메인 확정 시 제한 예정) |

- `application-local.yml`은 편의상 기본값을 담되, `application-dev.yml`/`application-prod.yml`은 시크릿 값을 파일에 직접 넣지 않고 `${ENV_VAR}` 플레이스홀더로 참조 → 실제 값은 배포 환경(CI/CD, 서버)의 환경변수로 주입.
- 로컬 개발 시 MariaDB/Redis는 Docker Compose로 기동(Redis는 `app.redis.enabled=false`로 두고 생략 가능).

---

## 8. 파일 스토리지 추상화 (S3 / 로컬 디스크)

포스트·프로필 사진 업로드는 컨트롤러/서비스에서 **동일한 함수**를 호출하고, 실제 저장 위치만 `app.storage.type` 설정(`local` | `s3`)으로 전환한다. Redis와 동일한 인터페이스 + `@ConditionalOnProperty` 패턴.

```
common/storage/
├─ FileStorageService.java         # interface
│    String issueUploadUrl(String key, String contentType)   # 업로드 대상 URL 발급
│    String issueDownloadUrl(String key)                      # 다운로드 URL 발급(인증된 사용자에게만)
│    void delete(String key)                                  # 삭제
├─ S3FileStorageServiceImpl.java   # @ConditionalOnProperty(name="app.storage.type", havingValue="s3")
│    - issueUploadUrl(): presigned PUT URL 발급(직접 업로드)
│    - issueDownloadUrl(): 짧은 TTL(예 10~15분)의 presigned GET URL 발급 — 실제 바이트는 S3/CDN이 직접 서빙
├─ LocalFileStorageServiceImpl.java # @ConditionalOnProperty(..., havingValue="local", matchIfMissing=true)
│    - issueUploadUrl(): 서버 자체 업로드 엔드포인트(`PUT /internal/files?key=`) 반환, `server/uploads/{key}`에 저장
│    - issueDownloadUrl(): 서버 자체 다운로드 엔드포인트(`GET /files?key=`) 반환
└─ FileDownloadController.java      # GET /files?key= — 컨트롤러 메서드라 §11 JwtAuthInterceptor가 정상 적용(인증 필요). 로컬 모드 실제 스트리밍 담당 + S3 모드에서 URL을 단건 재조회할 때도 사용 가능
```

> **왜 경로 변수(`{key}`)가 아니라 쿼리 파라미터인가**: `storage_key` 값 자체에 슬래시가 포함됨(예 `posts/{userId}/{date}/{uuid}.jpg` — 02 문서 §3). Spring MVC의 기본 `AntPathMatcher`는 `{key}` 경로 변수를 첫 슬래시에서 끊어버려서 전체 key를 하나의 변수로 못 받음. `{key:.+}` 같은 정규식 트릭도 가능하지만, `?key=`(쿼리 파라미터)로 받는 쪽이 URL 인코딩만 신경 쓰면 되고 더 단순함 — 업로드(`PUT /internal/files?key=`)·다운로드(`GET /files?key=`) 둘 다 동일하게 적용.

- 업로드: 컨트롤러(`post/`, `profile/`)는 `FileStorageService`만 의존 — 어떤 구현체가 주입되는지 몰라도 됨. `POST /posts/photos:upload-url` 같은 API 응답 형태는 두 모드 모두 동일, 클라이언트는 받은 URL로 PUT하면 끝(01 문서 §1.3 흐름 그대로).
- **다운로드는 이미지마다 별도 인증 호출을 만들지 않음**: 피드/포스트/프로필처럼 사진이 포함된 목록·상세 조회 API가 응답 DTO를 만들 때 서버가 각 `storage_key`에 대해 `issueDownloadUrl()`을 호출해 **URL을 이미 응답에 포함**시켜 내려준다. 그 조회 API 자체가 이미 §11에서 인증된 요청이므로, 이미지당 별도의 `GET /files?key=` 왕복이 필요 없다 — 클라는 응답에 담긴 URL로 바로 이미지를 로드(S3 모드=S3/CDN에서 직접, 로컬 모드=우리 서버에서 직접).
- `GET /files?key=`는 (a) 로컬 모드의 실제 파일 스트리밍을 처리하는 엔드포인트이자, (b) 만료된 presigned URL을 다시 받아야 하는 예외 상황의 보조 엔드포인트로만 사용.
- **인증 방식 차이**: S3 presigned URL은 URL 자체(쿼리 서명)에 인증이 담겨 있어 추가 헤더 없이도 만료 전까지 유효하지만, 로컬 모드의 업로드(`PUT /internal/files?key=`)와 다운로드(`GET /files?key=`)는 자체 서명이 없는 일반 서버 엔드포인트라 평소처럼 `Authorization: Bearer` 헤더가 필요함(클라의 REST 인터셉터가 자동으로 붙여줌 — 03 문서 §2).
- 설정 키: `app.storage.type`(local/s3), `app.storage.bucket`(s3 모드), `app.storage.download-url-ttl`(s3 모드, 기본 10분), `app.storage.local-path`(local 모드, 기본 `server/uploads`).
- local 모드는 별도 인프라 없이 바로 개발 가능(현재 인프라/호스팅 미정 상태에 적합), 인프라 확정 후 `app.storage.type=s3`로 전환하면 코드 변경 없이 이전 가능.

---

## 9. 외부 연동(소셜 로그인 / 번역)

### 9.1 소셜 로그인 (실 구현, 설정 파일 기반)

LINE/KAKAO/GOOGLE 각각을 **실제로 구현**한다. Provider별로 필요한 정보(client-id/secret, 검증 API URL 등)와 **사용 여부(enabled)** 를 모두 `application.yml`에서 설정으로 관리 — 코드 변경 없이 provider를 켜고 끌 수 있게 한다.

```
auth/social/
├─ SocialAuthProvider.java            # interface: SocialUserInfo verify(String providerToken)
├─ LineAuthProvider.java              # LINE 토큰 검증 API 호출
├─ KakaoAuthProvider.java             # KAKAO 토큰 검증 API 호출
├─ GoogleAuthProvider.java            # GOOGLE 토큰 검증 API 호출
├─ SocialAuthProperties.java          # @ConfigurationProperties(prefix="app.auth.social") — provider별 enabled/client-id/secret/verify-url 바인딩
└─ SocialAuthProviderRegistry.java    # enabled=true인 provider만 Map<SocialProvider, SocialAuthProvider>로 등록
```

설정 예(`application.yml`):
```yaml
app:
  auth:
    social:
      line:
        enabled: true
        client-id: ${LINE_CLIENT_ID:}
        client-secret: ${LINE_CLIENT_SECRET:}
        verify-url: https://api.line.me/oauth2/v2.1/verify
      kakao:
        enabled: true
        client-id: ${KAKAO_CLIENT_ID:}
        verify-url: https://kapi.kakao.com/v2/user/me
      google:
        enabled: false                # 키 발급 전까지는 꺼둠
        client-id: ${GOOGLE_CLIENT_ID:}
        verify-url: https://www.googleapis.com/oauth2/v3/tokeninfo
```

- `AuthService`는 요청의 `provider` 값으로 `SocialAuthProviderRegistry`에서 빈을 조회 — **enabled=false(또는 키 미설정)면 `PROVIDER_DISABLED`류 에러**로 응답, 서버가 죽지 않음.
- 각 `XxxAuthProvider.verify()`는 `RestClient`/`WebClient`로 해당 provider의 토큰 검증 API를 호출해 `providerUid`(+ 부가정보)를 얻고 `SocialUserInfo`로 반환 → `AuthService`가 `users` upsert 후 JWT 발급.
- 시크릿은 §7 원칙대로 `${ENV_VAR}` 플레이스홀더로 두고 실제 값은 환경변수/시크릿 매니저로 주입, 파일에 직접 커밋하지 않음.
- 프로필(local/dev/prod)별로 provider마다 `enabled`를 다르게 둘 수 있음 — 키가 발급된 provider부터 순차적으로 `enabled: true`로 열면 됨(§7 표 갱신).

### 9.2 번역
```
garden/translate/
├─ TranslationProvider.java          # interface: String translate(String text, String targetLang)
├─ PassthroughTranslationProvider.java  # 기본(app.translate.provider=none) — 원문 그대로 반환
└─ (추후) PapagoTranslationProvider.java 등 실제 공급자 구현
```
- `POST /translate`는 항상 같은 컨트롤러/서비스 흐름을 타되, `app.translate.provider` 설정값에 따라 Passthrough 또는 실제 번역 공급자로 스위칭. 키 없는 지금 단계에서도 API 계약(01 문서 §1.4)을 그대로 구현/테스트 가능.

---

## 10. CORS 설정 (임시 전체 오픈)

Spring Security를 쓰지 않으므로(§11) CORS는 순수 Spring MVC 방식으로 설정한다.

```
common/config/WebMvcConfig.java   # WebMvcConfigurer 구현
  addCorsMappings(registry):
    registry.addMapping("/**")
      .allowedOriginPatterns("*")
      .allowedMethods("*")
      .allowedHeaders("*")
      .allowCredentials(false)     // 주의: allowedOrigins("*") + allowCredentials(true) 조합은 Spring이 예외를 던짐
```

- 현재는 클라이언트 배포 형태(모바일 앱 전용 vs 웹 포함)가 유동적이므로 **전체 오픈**으로 시작.
- `allowCredentials(false)` 고정 — 인증은 쿠키가 아니라 `Authorization: Bearer` 헤더로 하므로 크리덴셜(쿠키) 공유가 필요 없고, 이 덕분에 와일드카드 오리진과도 충돌 없이 공존 가능.
- 추후 Flutter Web을 실제 웹 서버로 서빙하는 시점에 `allowedOriginPatterns`를 해당 도메인으로 제한하도록 변경 예정(TODO 주석으로 코드에 표시 권장).

---

## 11. 인증(JWT) — Spring Security 미사용, HandlerInterceptor 기반

REST/소켓 모두 상태 없는(stateless) JWT 검증만 필요하고 권한 체계(role/authority)가 복잡하지 않으므로, `spring-boot-starter-security` 없이 **`HandlerInterceptor`로 직접 구현**한다. Filter 대신 Interceptor를 쓰는 이유: DispatcherServlet 안(핸들러 매핑 이후)에서 동작해 인증 실패 시 기존 `GlobalExceptionHandler`(`@ControllerAdvice`)가 그대로 처리해주고, 매칭된 컨트롤러 메서드의 애노테이션을 직접 조회할 수 있어 인증 제외 대상을 애노테이션으로 표시할 수 있음.

```
common/security/
├─ JwtProvider.java          # jjwt로 토큰 생성/파싱·서명검증. REST 인터셉터와 WebSocket AUTH 패킷 처리에서 공용으로 사용
├─ JwtAuthInterceptor.java   # HandlerInterceptor 구현
├─ AuthContext.java          # ThreadLocal 기반 "현재 요청의 인증 사용자" 보관/조회 (SecurityContextHolder 대체)
└─ NoAuth.java                # 인증 제외 표시용 애노테이션(메서드/클래스에 부착)
common/config/
└─ WebMvcConfig.java          # addInterceptors()로 JwtAuthInterceptor 등록(+ §10의 CORS 설정도 같은 클래스)
```

`JwtAuthInterceptor` 동작:
- `preHandle(request, response, handler)`: `handler`가 `HandlerMethod`이고 메서드 또는 클래스에 `@NoAuth`가 있으면(예: `/auth/social`, `/auth/refresh`, `/system/gate`) 인증 없이 통과.
- 그 외에는 `Authorization` 헤더 파싱 → `JwtProvider`로 검증. 실패 시 커스텀 `UnauthorizedException`을 던짐 → `GlobalExceptionHandler`가 잡아 401 응답(`ApiResponse` 에러 포맷)으로 변환.
- **경로 기반 제외**: `@NoAuth`는 `HandlerMethod`(컨트롤러 메서드)에만 붙일 수 있는 애노테이션이라, 컨트롤러가 아닌 요청 — WebSocket 핸드셰이크(`/ws/**`, §4의 `WebSocketHttpRequestHandler`가 처리) — 에는 애노테이션으로 인증 제외를 표시할 방법이 없음. 인터셉터 등록 시 경로로 명시적으로 빼줘야 함:
  ```java
  registry.addInterceptor(jwtAuthInterceptor)
      .addPathPatterns("/**")
      .excludePathPatterns("/ws/**");
  ```
  누락 시 소켓 핸드셰이크가 인증 없이 막힘(설계상 인증은 연결 후 `AUTH` 패킷으로 처리하기로 했는데 핸드셰이크 단계에서부터 401). `GET /files?key=`(§8)는 정적 리소스가 아니라 일반 `@RestController` 메서드이므로 제외 목록에 넣지 않음 — 인터셉터가 정상 적용되어 인증이 걸림.
- 성공 시 `AuthContext`에 인증된 사용자 저장 후 `true` 반환.
- `afterCompletion`에서 **반드시 `AuthContext` ThreadLocal을 clear** — 서블릿 컨테이너 스레드풀이 스레드를 재사용하므로, 정리하지 않으면 다음 요청이 이전 요청의 인증 사용자를 이어받는 심각한 버그로 이어질 수 있음.
- 컨트롤러는 `AuthContext.currentUserId()`로 인증된 사용자 조회. 필요하면 커스텀 `@CurrentUser` 파라미터 리졸버(`HandlerMethodArgumentResolver`)를 추가해 `AuthContext.currentUserId()` 호출을 대체하는 것도 가능(선택).
- WebSocket 인증(§4의 `AUTH` 패킷 처리)도 같은 `JwtProvider`를 재사용 — REST/소켓 인증 로직이 이중화되지 않음.
- 트레이드오프: 세밀한 권한(role 기반 접근 제어, 메서드 시큐리티 애노테이션) 없이 직접 관리해야 하지만, 이 프로젝트 범위(로그인 여부만 확인)에는 충분하고 의존성/설정이 가벼움. 추후 역할 기반 정책이 복잡해지면 Spring Security 도입을 재검토.
