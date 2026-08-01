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

## 1. 현재 상태 스냅샷 (2026-08-01 기준)

**한 줄 요약**: 정적 UI 11개 화면 완성 + **로그인/온보딩은 로컬 서버·DB와 실제 연동 완료**(첫 수직 슬라이스). 나머지 화면은 아직 더미 데이터.

| 영역 | 상태 |
|------|------|
| 기획 | **Plan_2** 기준 (`D:\MyProject\Plan_Chat\Plan_2` — BM 추가, 운영시간 17~06시). Plan_1은 구버전 |
| 클라 UI | 로그인·온보딩3·홈·달빛가든·대화방·채팅창·친구·프로필 (11화면, 다크 테마) |
| 클라 데이터 | **Riverpod + go_router + Dio + secure storage** 도입. 인증/프로필만 실연동, 나머지 화면은 하드코딩 |
| 서버 | Spring Boot. **auth(소셜 추상화 + mock) / profile 도메인만 구현**. post·garden·chat·friend·luna·store·scheduler 미구현 |
| DB | 로컬 MariaDB 11.4.5, Flyway **V1 적용됨**(17테이블). BM/친구양방향 테이블은 **문서에만 있고 DDL 미반영**(V2 필요) |
| 실기기 검증 | 에뮬(Pixel_10) → 로컬 서버 → DB **end-to-end 성공**, 앱 재시작 자동 로그인 확인 |

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

---

## 4. 세션 로그

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

## 5. 다음 작업 후보

1. **나머지 화면 실데이터 연결** — 홈/프로필부터(`GET /me` 이미 있음). 그 외는 서버 도메인 구현이 선행돼야 함.
2. **서버 남은 도메인 구현** — post → garden → chat(+WebSocket) → friend → luna → store(BM) → scheduler. [01](01-protocol-api-spec.md) 명세대로.
3. **V2 마이그레이션** — BM 테이블 5종(`subscriptions`/`user_entitlements`/`boost_inventory`/`boost_activations`/`daily_usage`) + `chat_rooms.type(MATCH|FRIEND)` + `friendships` 양방향 구조 + `luna_transactions.reason` 값 추가. ([02 §1.7](02-db-schema.md))
4. **BM 화면 6종 신규** — 루나상점·프라임 멤버십·루나 충전샵·포스트 부스트·앨범 패스·자동 번역 패스 (Plan_2 화면 25~30).

**대기 중**: 친구 기획 보완 문서(요청/수락 흐름 세부, 친구 최대수 20 vs 30 모순). 소셜 로그인 키, 인앱결제/광고 계정.
