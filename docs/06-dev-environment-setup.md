# 달빛톡 — 개발 환경 세팅 (다른 디바이스 재현용)

> 목적: 여러 기기에서 **동일한 환경으로 이어서 작업**하기 위한 세팅 가이드.
> 새 기기에서 `git clone` 후 이 문서대로 세팅하면 오늘까지의 작업을 그대로 이어갈 수 있다.
> 레포는 **모노레포**: `lib/`(Flutter 클라) · `server/`(Spring Boot) · `docs/`(설계/문서).

---

## 0. 공통 — 저장소 받기
```bash
git clone https://github.com/BoongLee50/project_chat
```
- 협업 계정은 GitHub 저장소 Collaborator로 초대되어 있어야 함(Private인 경우).
- clone 후 각 파트별로 아래 세팅.

---

## 1. 클라이언트 (Flutter) — 빌드/실행

| 도구 | 버전/비고 |
|------|-----------|
| Flutter SDK | **stable 채널** (Dart SDK `^3.12.2`) |
| Android Studio | Android SDK + 에뮬레이터 + 내장 JBR(21) |
| (선택) VS Code | Flutter/Dart 확장 |

```bash
# 저장소 루트에서
flutter pub get          # 의존성 + .dart_tool 생성 (git엔 없음, 각 기기에서 생성)
flutter analyze          # 무경고여야 정상
flutter test             # 통과여야 정상
flutter run -d <device>  # 에뮬레이터/실기기에서 실행
```
- 검증에 쓴 에뮬레이터: **Pixel_10** (`flutter emulators --launch Pixel_10`).
- Android 빌드 툴은 프로젝트에 고정(Gradle 9.1.0 / AGP 9.0.1 / Kotlin 2.3.20)되어 있어 별도 설치 불필요.

---

## 2. 서버 (Spring Boot) — 빌드

**핵심: JDK 17만 있으면 된다. Gradle은 래퍼가 자동 처리.**

| 도구 | 버전/비고 |
|------|-----------|
| **JDK 17** (필수) | Spring Boot 3.3.4가 17 요구. 오늘 사용: **Adoptium Temurin 17.0.19**. |
| Gradle | **설치 불필요** — `server/`에 Gradle 래퍼(8.10.2) 커밋됨. `./gradlew`가 자동 다운로드/실행. |

**JDK 17 설치 (기기마다 1회)**
- Adoptium Temurin 17 다운로드: <https://adoptium.net> (또는 API: `https://api.adoptium.net/v3/binary/latest/17/ga/<os>/x64/jdk/hotspot/normal/eclipse`)
- 설치/압축해제 후 **`JAVA_HOME`을 그 JDK 17 경로로 지정**.
- ⚠️ 주의: **안드로이드 스튜디오 내장 JBR은 21**이라 서버 toolchain(17)과 major 버전이 달라 매칭 안 됨 → **별도 JDK 17 설치 필요.**

**빌드**
```bash
cd server
# JAVA_HOME을 JDK 17로 지정한 상태에서:
./gradlew assemble        # 컴파일 + bootJar 생성 (성공하면 서버 코드 정상)
# (git-bash on Windows 예)
JAVA_HOME="/c/경로/jdk-17" ./gradlew assemble
```
- **오늘 이 PC(Windows) 기준 실제 경로** (참고용, 기기마다 다름):
  - JDK 17: `D:\dev-tools\jdk-17.0.19+10`
  - (Gradle 배포판도 `D:\dev-tools\gradle-8.10.2`에 받아뒀으나, 래퍼가 있으므로 다른 기기에선 불필요)
- 첫 빌드는 의존성 다운로드로 1~2분 소요. `BUILD SUCCESSFUL` + `bootJar` 나오면 OK.

---

## 3. 서버 실행 (⏸ 아직 미완 — 로컬 MariaDB 필요)

> 오늘은 **컴파일까지만** 검증. 실행(`bootRun`)은 DB가 있어야 가능(Flyway가 시작 시 스키마 적용 + DB 접속).

향후 세팅 예정:
- **로컬 MariaDB** 설치 → `server/src/main/resources/application-local.yml`의 DB 접속정보 맞추기 → Flyway가 `db/migration/V1__init_schema.sql` 자동 적용.
- **Redis는 선택**: `app.redis.enabled=false`(기본)로 생략 가능(단일 인스턴스 개발).
- 실행: `cd server && ./gradlew bootRun` (프로필 `local` 기본).
- 상세: [05 서버 구조](05-server-structure.md).

---

## 4. 오늘까지 검증된 상태
- **클라**: 정적 UI 11개 화면 — Android 에뮬레이터 검증 완료.
- **서버**: `./gradlew assemble` **컴파일 성공** (실행은 MariaDB 세팅 후).

## 5. 버전 요약
| 대상 | 버전 |
|------|------|
| Flutter | stable (Dart `^3.12.2`) |
| Android Gradle / AGP / Kotlin | 9.1.0 / 9.0.1 / 2.3.20 |
| 서버 JDK | 17 (Temurin 17.0.19 사용) |
| 서버 Gradle(래퍼) | 8.10.2 |
| Spring Boot | 3.3.4 |
| DB | MariaDB (설치 예정) |
