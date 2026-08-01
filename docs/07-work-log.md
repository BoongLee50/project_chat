# 달빛톡 — 작업 로그 & 인수인계 (WORK LOG)

> **이 문서의 목적**: 여러 기기 / 여러 AI 세션(Claude)에서 **같은 맥락으로 이어서 작업**하기 위한 단일 진입점.
> 새 기기·새 세션에서 작업을 시작하면 **이 문서를 먼저 읽고**, §1(현재 상태) → §2(재개 절차) 순으로 따라오면 된다.
> 작업을 진행하면 **§4에 세션 로그를 추가**하고 [04 로드맵](04-progress-and-roadmap.md)도 함께 갱신할 것.

문서 지도
| 문서 | 내용 |
|------|------|
| [01](01-protocol-api-spec.md) | REST/WebSocket API 명세 (클라·서버 계약) |
| [02](02-db-schema.md) | DB 스키마 (MariaDB + Redis(선택)) |
| [03](03-flutter-structure.md) | Flutter 구조 |
| [04](04-progress-and-roadmap.md) | 진행 현황·남은 작업·미결정 사항 |
| [05](05-server-structure.md) | Spring Boot 서버 구조 |
| [06](06-dev-environment-setup.md) | 개발 환경 세팅(기기별 1회) |
| **07(이 문서)** | 작업 로그 · 재개 절차 · 함정 모음 |

---

## 1. 현재 상태 스냅샷 (2026-08-02 기준, 커밋 `b6db067`)

**한 줄 요약**: 화면 11개 완성. **로그인/온보딩 · 프로필 · 홈(오늘의 포스트) · 달빛가든 · 대화방/채팅창(WebSocket 실시간)** 까지 로컬 서버·DB와 실제 연동 완료. **친구 탭만 아직 더미**(friend 도메인 미구현).

| 영역 | 상태 |
|------|------|
| 기획 | **Plan_2** 기준 (`D:\MyProject\Plan_Chat\Plan_2` — BM 추가, 운영시간 17~06시). Plan_1은 구버전 |
| 클라 UI | 로그인·온보딩3·홈·달빛가든·대화방·채팅창·친구·프로필 (11화면, 다크 테마) |
| 클라 데이터 | **Riverpod + go_router + Dio + secure storage + image_picker + web_socket_channel**. 인증·프로필·포스트·달빛가든·**대화방/채팅** 실연동, **친구만 하드코딩** |
| 서버 | Spring Boot. **auth(mock 포함) / profile / post / garden / chat(+WebSocket) / luna(내부용) 도메인 구현**. friend·store(BM)·scheduler 미구현 |
| DB | 로컬 MariaDB 11.4.5, Flyway **V4까지 적용**(V1 초기 + V2 posts 등록창/교체 + V3 post_comments + V4 chat: 메시지 500자·`chat_rooms.type`·`daily_usage`). BM 테이블·친구 양방향은 **DDL 미반영 → 다음은 V5** |
| 실기기 검증 | 에뮬(Pixel_10) → 로컬 서버 → DB/디스크 **end-to-end 성공**: 자동 로그인, 프로필, 카메라 촬영→업로드→표시, 가든 피드/좋아요/댓글, **에뮬 2대 양방향 실시간 채팅** |

**남은 화면/기능 한눈에**: 친구(요청·수락·목록) · BM 화면 6종(25~30) · 신고/차단 팝업 · 관심사/지역/소개 편집 팝업 · 다국어(한↔일) · 스케줄러.

**작업 분담**: 서버 개발자(abombspy) = 초기 뼈대 + 추후 클라우드(AWS) 배포. 그 사이 실제 개발(서버 도메인 + 클라 연동 + 로컬 통합)은 이 저장소에서 직접 진행.

---

## 2. 다른 기기에서 이어서 작업 시작하기

### 2-1. 최초 1회 — 환경 세팅
[06 개발환경 세팅](06-dev-environment-setup.md) 참고. 요약:
1. `git clone https://github.com/BoongLee50/project_chat`
2. **Flutter**(stable) + **Android Studio**(SDK·에뮬레이터)
3. **JDK 17** 별도 설치 (⚠️ 안드로이드 스튜디오 내장 JBR은 21이라 서버 toolchain 17과 불일치)
4. **MariaDB 11.4.x** (무설치 ZIP) + DB/계정 생성 — 이름·계정·비번 모두 `moonlighttalk`
5. Gradle은 설치 불필요(`server/gradlew` 래퍼 커밋됨)

### 2-2. 매번 — 개발 시작 루틴
```bash
# ① MariaDB 기동 (재부팅하면 꺼짐)
<MariaDB>/bin/mariadbd.exe --datadir="<데이터경로>" --port=3306 --console

# ② 서버 기동 (Flyway가 스키마 자동 적용)
cd server && JAVA_HOME="<jdk17>" ./gradlew bootRun

# ③ 에뮬레이터 + 앱
flutter emulators --launch Pixel_10
flutter run -d emulator-5554
```
확인: `curl http://localhost:8080/system/gate` → `{"open":...,"nextOpenAt":"..."}`

**⚠️ 채팅(WebSocket)을 건드릴 땐 반드시 `adb reverse` 방식으로.**
기본값 `10.0.2.2`는 에뮬레이터 NAT가 소켓을 30~60초마다 끊어서 실시간 검증이 불가능하다(함정 #12).
```bash
# 기기마다 1회 (에뮬 재시작하면 다시)
adb -s emulator-5554 reverse tcp:8080 tcp:8080
adb -s emulator-5556 reverse tcp:8080 tcp:8080

# localhost 로 붙게 빌드/실행
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://localhost:8080
```

**에뮬 2대로 채팅 테스트하기**
```bash
flutter emulators --launch Pixel_10          # 첫 번째 → emulator-5554
flutter emulators --launch Pixel_10          # 두 번째 → emulator-5556
```
- 두 기기에서 **서로 다른 소셜 버튼**으로 로그인해야 다른 계정이 된다(`dev-line` / `dev-kakao` / `dev-google`).
- 흐름: A 달빛가든에서 B에게 **대화 신청** → B 대화방에 신청 카드 → **수락** → 양쪽에 방 생성 → 채팅.
- 소켓 상태는 앱 로그로 확인: `adb -s <기기> logcat -d | grep "\[socket\]"` → `연결됨` / `AUTH_OK` / `연결 종료됨`.
- 서버 쪽은 `소켓 인증 성공` / `소켓 종료 ... status=` / `푸시 op=... 세션수=` 로그로 추적.

### 2-3. 로그인 방법 (실제 소셜 키 없음)
소셜 3사 키가 아직 없어 **개발용 목 로그인**을 쓴다.
- 서버: `application-local.yml`의 `app.auth.social.mock.enabled: true` → `MockAuthProvider`가 비활성 provider 자리를 대체.
- 클라: 소셜 버튼을 누르면 `dev-line` / `dev-kakao` / `dev-google` 토큰을 전송 → **버튼마다 다른 테스트 계정**이 된다.
- 계정 초기화하려면 DB에서 해당 `users` row 삭제(또는 DB 재생성 후 서버 재기동).

---

## 3. 반드시 알아야 할 함정 (실제로 겪은 것들)

| # | 함정 | 대응 |
|---|------|------|
| 1 | **에뮬레이터의 `localhost`는 호스트 PC가 아님** | API base URL 기본값 **`http://10.0.2.2:8080`**(AppConfig). 실기기는 PC의 LAN IP를 `--dart-define=API_BASE_URL=`로 주입 |
| 2 | **MariaDB는 생성 컬럼(GENERATED ALWAYS AS)에서 CONCAT/LEAST/GREATEST 불허**(err 1901) | `chat_rooms.active_pair_key`를 앱이 채우는 일반 컬럼으로 변경(커밋 `40d9130`). **향후 마이그레이션에서도 생성 컬럼에 문자열 함수 쓰지 말 것** |
| 3 | JDK 버전 | 서버 toolchain=**17**. 안드로이드 스튜디오 JBR(21)로는 빌드 안 됨 |
| 4 | Flyway는 **적용된 마이그레이션 수정 불가**(체크섬) | 스키마 변경은 **V2, V3…** 새 파일로 추가 |
| 5 | 서버 응답 날짜 포맷 | **ISO-8601 문자열**(`"2026-08-01T17:00:00"`). 클라 DTO는 `DateTime.tryParse` |
| 6 | Redis | `app.redis.enabled=false`로 **없이도 동작**(단일 인스턴스). 수평 확장 시에만 필요 |
| 7 | adb 자동 탭 좌표 | 스크린샷(1080x2424) 기준으로 계산. 표시 이미지 좌표에 **×1.21** 해야 실제 좌표 |
| 8 | **Windows: pub 캐시(C:)와 프로젝트(D:)가 다른 드라이브** → 플러그인 Kotlin 증분 컴파일 실패(`different roots`) | `android/gradle.properties`에 `kotlin.incremental=false` (커밋 `c47aced`) |
| 9 | 로컬 스토리지 업로드 경로 | 서버 작업디렉터리 기준이라 실제 저장 위치는 **`server/server/uploads/`** (gitignore 처리됨) |
| 10 | 서버가 주는 이미지 URL | **상대경로**(`/files?key=`) + **인증 헤더 필요** → baseUrl 접두 + `Image.network(headers:)` (`authHeadersProvider`) |
| 11 | Windows 셸에서 curl로 한글 JSON 전송 | 인코딩이 깨져 500 → python으로 UTF-8 파일 작성 후 `--data-binary @file` |
| 12 | **에뮬레이터 NAT(`10.0.2.2`)가 WebSocket을 30~60초마다 끊음** (서버 로그 `CloseStatus 1006` + `EOFException`) | **서버 문제 아님**(호스트에서 직접 붙이면 150초+ 무중단). 소켓 테스트는 반드시 아래 `adb reverse` 방식으로: <br>`adb -s <기기> reverse tcp:8080 tcp:8080` <br>`flutter build apk --debug --dart-define=API_BASE_URL=http://localhost:8080` |
| 13 | `WebSocketChannel.connect()`는 **핸드셰이크 실패/지연을 던지지 않음** | `await channel.ready.timeout(10s)` 필수. 안 기다리면 연결 실패해도 `_channel`이 남아 **모든 send가 조용히 버려지고 재연결도 안 걸린다** |
| 14 | `WebSocketSession`은 **동시 전송에 안전하지 않음** | 내 ACK와 상대 읽음영수증이 다른 스레드에서 같은 세션에 쓰이면 세션이 깨진다 → `ConcurrentWebSocketSessionDecorator`로 감싸 등록 |

---

## 4. 세션 로그

### 2026-08-01(5) — 대화방/채팅창 실연동 (chat + WebSocket) (`2886dd5`~`b6db067`)
**한 일**
1. **서버 chat 도메인 + WebSocket**(`2886dd5`) — V4(메시지 body 500자, `chat_rooms.type`, `daily_usage`), 대화 신청(무료 2회/일 → 이후 루나 5), 수락 시 방 생성(중복 방지), 소켓 봉투 `{op,seq,ts,data}`(AUTH/PING/ROOM_SUBSCRIBE/CHAT_SEND/CHAT_READ + 서버 푸시 CHAT_RECV·CHAT_SENT_ACK·UNREAD_COUNT·ROOM_STATE·CHAT_READ_RECEIPT·CHAT_REQ_INCOMING).
2. **클라 소켓 클라이언트 + 대화방/채팅창 연동** — `SocketClient`(AUTH·하트비트·지수 백오프 재연결), 대화방 목록(받은/보낸 신청, 미확인 배지), 채팅창(히스토리 REST + 실시간 소켓, 읽음 표시, 나가기), 달빛가든에서 대화 신청 다이얼로그.

**에뮬 2대 실검증**(Nari↔Suho): 신청 → 상대 실시간 수신 → 수락 → 방 생성 → **양방향 실시간 메시지** → 읽음(파란 ✓✓) → **목록 자동 갱신**(수동 새로고침 없이)까지 전부 확인.

**이번에 잡은 버그(중요)**
- `channel.ready`를 안 기다려 연결 실패 시 send가 **조용히 유실** → 타임아웃(10초) 붙이고 실패 시 재연결. 전송 실패는 스낵바 + 입력값 복구로 사용자에게 노출.
- 서버가 같은 세션에 **동시 write** 하며 세션이 깨짐 → `ConcurrentWebSocketSessionDecorator` 적용.
- AUTH_FAIL(액세스 토큰 만료) 무시하던 것 → **토큰 갱신 후 재연결**(`DioClient.refreshTokens()` 재사용).
- 재연결 후 상태 불일치 → **AUTH_OK 수신 시 방 목록 refresh + 방 재구독/재조회**.
- half-open 대비 90초 무수신 시 강제 재연결.
- (환경) 에뮬레이터 NAT가 소켓을 끊는 문제는 `adb reverse`로 우회 — 함정표 #12.

### 2026-08-01(4) — 달빛가든 도메인 + 화면 연동 (`9ad67c6`~`8ff267f`)
**한 일**
1. **IAP 문서 반영**(`9ad67c6`) — 결제는 `POST /store/purchases:verify`(서버 영수증 검증 + purchaseToken 멱등) + 스토어 웹훅 구조로 개편. IAP 대상은 루나 충전·프라임 구독만(루나 소비 상품은 내부 처리). LINE은 로그인용이지 결제 아님.
2. **서버 garden 도메인**(`55609c4`) — **V3: post_comments**(V1 설계 누락분) + Post Score(Pick·Online·Recency·Engage) 정렬, 차단/신고/스킵/필터 제외, 노출수 원자 증가, 좋아요·스킵·댓글·번역(패스스루).
3. **달빛가든 화면 연동**(`8ff267f`) — 피드 렌더, **필터 실제 동작**, 스포트라이트 토글, 스와이프 스킵, 좋아요, 댓글 시트. `AuthedImage` 공용 위젯 추출.

**검증**: 테스트 유저 3명 시드 → 피드 노출·스코어, 앱에서 좋아요(likes=1)·댓글(post_comments 저장)·스킵(다음 피드에서 제외), 노출 시 exposures 증가 — 전부 DB로 확인.

**메모**: Pick Point는 부스트 테이블(BM) 도입 전이라 **임시로 프리미엄 여부**로 대체 중. 시드 사진이 1px 투명 PNG라 피드 이미지가 검게 보이는 것은 데이터 문제(정상).

### 2026-08-01(3) — 홈 화면 post API 실연동 (`c47aced`)
**한 일**: 클라 post 데이터 레이어(DTO·PostApi·myPostProvider) + 홈 화면 전면 연동 —
사진 촬영(image_picker 카메라)→업로드→표시, 삭제, 좌우 탭 전환, 남은 시간("PASS" 포함),
하루 한마디 편집, 공유하기. 인증 이미지 로드용 `authHeadersProvider` 추가.

**검증**: 에뮬 카메라 촬영 → 서버 디스크 저장 + DB 반영 → 화면 표시까지 전 사이클 성공.

**함정 추가**: ① Windows에서 pub 캐시(C:)와 프로젝트(D:)가 다른 드라이브면 Kotlin 증분
컴파일이 깨짐(`different roots`) → `android/gradle.properties`에 `kotlin.incremental=false`.
② 로컬 스토리지 업로드 경로는 서버 작업디렉터리 기준이라 실제로는 `server/server/uploads/`.
③ 서버가 주는 이미지 URL은 **상대경로**(`/files?key=`)이고 **인증 헤더 필요** → baseUrl 접두 + headers.

**남은 것**: 루나 잔액·달 위상·좋아요/댓글 수치는 각 도메인(luna/garden) 구현 후 연결.

### 2026-08-01(2) — 프로필/홈 실데이터 + 서버 post 도메인 (`b9310ba`~`ac2ab64`)
**한 일**
1. **프로필/홈 화면 실데이터 연결**(`b9310ba`) — `GET /me` 기반. 프로필: 닉네임·나이·국가·프리미엄 배지, 사진 미등록 플레이스홀더, 관심사/소개/지역 빈 상태 안내, 당겨서 새로고침, **로그아웃 메뉴(계정 전환 테스트용)**. 홈: 이름·나이·국기.
2. **서버 post(오늘의 포스트) 도메인 구현**(`ac2ab64`) — V2 마이그레이션(`posts.window_started_at`, `replace_count`), `GateService.currentSessionDate()`(영업일 06시 롤오버), PostService/Controller 6개 엔드포인트.

**검증**: 프로필/홈에 실제 계정(Nari/23/KR) 표시. post API curl 전 구간 — 창 시작·남은시간 카운트다운, 업로드URL→사진등록, 한마디, 공유(published=true), **3장째 409**(일반 2장 제한).

**참고**: Windows 셸에서 curl로 한글 JSON을 보내면 인코딩이 깨져 500이 난다 → `python`으로 UTF-8 파일을 만들어 `--data-binary @file` 사용할 것(서버 버그 아님).

**남은 것**: post 화면(홈)의 사진/한마디/공유를 서버와 연결(현재 홈은 이름만 실데이터, 나머지 더미). garden/chat/friend/luna/store 도메인 미구현.

### 2026-08-01 — 로컬 풀스택 구동 + 첫 수직 슬라이스 (`eb6b335`~`431dae9`)
**한 일**
1. **기획 Plan_2 반영**(`eb6b335`, `deb9c27`) — BM 8장 신규(프라임/루나상점/부스트/앨범패스/번역패스), 운영시간 18~05 → **17~06**, 친구 **양방향** 확정. 문서 01·02·04·05 + 클라 `AppConfig`·로그인 문구 갱신.
2. **로컬 MariaDB 구축 + 서버 기동 성공**(`40d9130`, `eedfdd8`) — MariaDB 11.4.5 ZIP 설치, DB/계정 생성, Flyway V1 적용(17테이블), Spring Boot 8080 구동. 이 과정에서 **MariaDB 생성 컬럼 비호환 발견·수정**(함정 #2) + 서버 게이트 17/6 반영.
3. **클라 데이터 레이어 + 로그인/온보딩 실연동**(`431dae9`) — Riverpod+go_router(세션 기반 리다이렉트), DioClient(JWT 첨부·401 refresh 재시도), TokenStorage, auth/profile API·DTO, 서버 `MockAuthProvider` 추가.

**검증**: 에뮬 → 로컬 서버 → MariaDB. 로그인→닉네임(서버 중복검사)→출생년도→성별/국가→`POST /profile`→홈, DB row 확인(`Nari/2003/FEMALE/KR`), **앱 재시작 시 자동 로그인** 확인.

**결정**: 상태관리 **Riverpod + go_router** 확정. 대화 신청 일일 무료 **2회**(기획서 "1명"은 오기). 친구 = **양방향(상호 동의)**, 친구가 되면 **야간 게이트와 무관하게 24시간 상시 대화방**.

### 2026-07-28 — 서버 합류 + 로컬 빌드 환경 (`9fc8351`~`f2a22a1`)
- 서버 개발자(abombspy)가 **Spring Boot 초기 구현** 푸시(스택 확정: Spring Boot + MariaDB/MyBatis + Redis 선택, auth/profile 도메인, Flyway V1, 공통 인프라).
- 이쪽에서 JDK 17 + Gradle 래퍼로 **서버 컴파일 성공 검증**, [06 개발환경 문서] 작성.

### 2026-07-12·19 — 정적 UI 완성 (`c1de6cf`~`f7ce807`)
- 설계 문서 01~04, feature-first 스캐폴딩, 다크 테마, **화면 11개**(로그인·온보딩3·홈·달빛가든·대화방·채팅창·친구·프로필) + 메인 5탭 셸. 전부 에뮬레이터 검증.
- 채팅 보관 정책 확정: 서버 **30일 보관 후 오래된 순 삭제(FIFO)**, 클라는 UI에서만 삭제.

---

## 5. 다음 작업 후보 (이 순서로 이어가면 됨)

1. **friend 도메인 + 친구 탭 연동** — **양방향 동의** 방식(단방향 등록 아님). 요청→수락해야 친구 성립, 친구가 되면 **운영시간(17~06시) 밖에도 대화방 상시 유지**(`chat_rooms.type=FRIEND`은 게이트 예외). V5에 `friendships`(requester/addressee/status/pair_key) 필요.
2. **luna / store(BM) 도메인** + **V5 마이그레이션** — BM 테이블(`subscriptions`/`user_entitlements`/`boost_inventory`/`boost_activations`) + `luna_transactions.reason` 값 추가. `daily_usage`와 `chat_rooms.type`은 **V4에서 이미 생성됨**. ([02 §1.7](02-db-schema.md))
   - 결제는 `POST /store/purchases:verify`(서버 영수증 검증 + purchaseToken 멱등) + 스토어 웹훅. IAP 대상은 **루나 충전·프라임 구독만**([01 §1.8](01-protocol-api-spec.md)).
3. **BM 화면 6종 신규** — 루나상점·프라임 멤버십·루나 충전샵·포스트 부스트·앨범 패스·자동 번역 패스 (Plan_2 화면 25~30).
4. **scheduler** — 17시 오픈/06시 초기화(포스트·스코어·daily_usage), 채팅 30일 FIFO 삭제, 종료 방 정리.

**같이 정리하면 좋은 잔여 항목**
- 채팅창 팝업 미구현분: 프로필 보기 / 신고하기 / 차단하기 (현재 메뉴만 있고 동작은 "나가기"만).
- 가든 Pick Point가 부스트 테이블 도입 전이라 **임시로 프리미엄 여부**로 대체 중 → BM 도입 시 교체.
- 시드 사진이 1px 투명 PNG라 피드 이미지가 검게 보임(데이터 문제, 코드 정상).

**대기 중(외부 입력 필요)**: 친구 기획 보완 문서(요청/수락 흐름 세부, 친구 최대수 20 vs 30 모순). 소셜 로그인 키, 인앱결제/광고 계정.
