# 달빛톡 서버 (Spring Boot)

설계 문서: [../docs/05-server-structure.md](../docs/05-server-structure.md) · [../docs/02-db-schema.md](../docs/02-db-schema.md) · [../docs/01-protocol-api-spec.md](../docs/01-protocol-api-spec.md)

## ✅ 빌드 검증 완료

임시로 내려받은 JDK 17(Temurin 17.0.19) + 로컬 Gradle 8.9로 `compileJava` · `test` · `build`(bootJar 패키징 포함)까지 모두 성공 확인했습니다. 단, **MariaDB가 이 환경에 없어 실제 기동(부트업)·API 호출·DB 연동까지는 검증하지 못했습니다.** 유닛 테스트(`JwtProviderTest` 3건, `NicknameValidatorTest` 6건, 총 9건)는 DB 없이 통과하는 순수 로직만 다룹니다.

> Spring Boot 3.x 자체가 최소 JVM 17을 요구해서(Gradle 플러그인 해석 단계부터 17 미만이면 실패), Gradle을 **실행하는** JVM도 17 이상이어야 합니다 — 프로젝트의 `java.toolchain`(컴파일 대상)만 17로 지정해서는 부족합니다.

## 사전 준비물 요약

| 항목 | 버전 | 필수 여부 |
|------|------|----------|
| JDK | 17 이상 | 필수 (Gradle을 **실행하는** JVM도 17+ 필요) |
| MariaDB | 10.4 이상 | 필수 |
| Gradle | 8.x (wrapper 미포함, 시스템 설치 필요) | 필수 |
| Redis | 아무 버전 | 선택 (`app.redis.enabled=true`일 때만) |
| Docker | Desktop 최신 | 선택이지만 DB/Redis를 가장 빠르게 띄우는 방법 |

---

## 1. JDK 17 설치

**Windows (winget)**
```powershell
winget install EclipseAdoptium.Temurin.17.JDK
```
설치 후 새 터미널에서 확인:
```powershell
java -version   # openjdk version "17..." 이 나와야 함
```
여러 JDK가 공존한다면(이 프로젝트 개발 PC처럼 8/11이 기본일 수 있음) 이 서버 빌드 전용으로 `JAVA_HOME`을 17로 임시 지정하세요.
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.x.x.x-hotspot"
$env:Path = "$env:JAVA_HOME\bin;" + $env:Path
```
**macOS/Linux**
```bash
brew install temurin17        # macOS
sdk install java 17.0.13-tem  # sdkman 사용 시(모든 OS)
```

## 2. Gradle 준비

이 저장소에는 Gradle Wrapper(`gradlew`)가 없습니다(네트워크 제한 환경에서 wrapper jar를 만들 수 없어 제외). 아래 중 하나로 준비하세요.

- **시스템 Gradle 설치**: `winget install Gradle.Gradle`(Windows) / `brew install gradle`(macOS) / [gradle.org](https://gradle.org/install/) 참고
- **Wrapper 직접 생성**(Gradle이 이미 있다면 `server/` 안에서 한 번만):
  ```bash
  gradle wrapper --gradle-version 8.9
  ```
  이후로는 `./gradlew`(맥/리눅스) 또는 `gradlew.bat`(윈도우)로 wrapper 없이도 항상 같은 Gradle 버전을 씁니다. 생성된 `gradlew`/`gradlew.bat`/`gradle/wrapper/`는 커밋해도 됩니다.

빌드 시엔 **Gradle을 실행하는 JVM**(`JAVA_HOME`)이 17 이상이어야 합니다 — 컴파일 대상 버전(`build.gradle.kts`의 `java.toolchain`)만 17로 지정해서는 부족합니다(Spring Boot 3.x 플러그인 자체가 Gradle 해석 단계부터 17을 요구).

## 3. MariaDB 설치 및 설정

### 3-A. Docker로 띄우기 (권장 — 가장 빠름)
```bash
docker run -d --name moonlighttalk-mariadb \
  -e MARIADB_DATABASE=moonlighttalk \
  -e MARIADB_USER=moonlighttalk \
  -e MARIADB_PASSWORD=moonlighttalk \
  -e MARIADB_ROOT_PASSWORD=root \
  -p 3306:3306 mariadb:11
```
`application-local.yml`의 접속 정보(`moonlighttalk`/`moonlighttalk`/db명 `moonlighttalk`)와 그대로 맞춰져 있어 별도 설정 없이 바로 붙습니다. 기동 확인:
```bash
docker logs -f moonlighttalk-mariadb   # "ready for connections" 뜨면 완료
docker exec -it moonlighttalk-mariadb mariadb -umoonlighttalk -pmoonlighttalk moonlighttalk -e "SHOW TABLES;"
```
(서버를 최소 한 번 기동해 Flyway가 스키마를 적용한 뒤에는 `users`, `chat_rooms` 등 테이블 목록이 보여야 정상입니다.)

### 3-B. 로컬에 직접 설치하는 경우 (Docker 없이)
1. [MariaDB 다운로드](https://mariadb.org/download/) 또는 Windows는 `winget install MariaDB.Server`
2. 설치 후 관리자 계정으로 접속해 DB/사용자 생성:
   ```sql
   CREATE DATABASE moonlighttalk CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   CREATE USER 'moonlighttalk'@'%' IDENTIFIED BY 'moonlighttalk';
   GRANT ALL PRIVILEGES ON moonlighttalk.* TO 'moonlighttalk'@'%';
   FLUSH PRIVILEGES;
   ```
3. `application-local.yml`의 `spring.datasource.url`이 `localhost:3306`을 가리키는지 확인(포트를 바꿨다면 이 파일도 수정).

### 3-C. 스키마 적용
별도 작업 불필요 — 서버가 기동될 때 **Flyway가 `src/main/resources/db/migration/V1__init_schema.sql`을 자동 실행**합니다(local/dev 프로필 기준, prod는 `spring.flyway.enabled=false`라 배포 파이프라인에서 수동 실행 — [05 문서 §7](../docs/05-server-structure.md) 참고). 수동으로 먼저 적용해보고 싶다면:
```bash
docker exec -i moonlighttalk-mariadb mariadb -uroot -proot moonlighttalk < server/src/main/resources/db/migration/V1__init_schema.sql
```

## 4. (선택) Redis 설치

`app.redis.enabled=false`(local 프로필 기본값)면 설치하지 않아도 됩니다. 테스트해보고 싶다면:
```bash
docker run -d --name moonlighttalk-redis -p 6379:6379 redis:7
```
그리고 `application-local.yml`에서 `app.redis.enabled: true`로 바꾸면 프레즌스 등이 Redis를 사용하도록 전환됩니다([05 문서 §2](../docs/05-server-structure.md)).

## 5. 서버 설정(환경변수)

로컬 개발은 `application-local.yml`에 더미 값이 들어 있어 아무 환경변수 없이도 기동됩니다. 아래는 실제 값을 채워야 하는 항목(dev/prod 또는 실제 기능 검증 시):

| 환경변수 | 용도 | 비고 |
|---------|------|------|
| `APP_JWT_SECRET` | JWT 서명 키 | 운영에서는 반드시 교체 |
| `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` | DB 접속 정보 | dev/prod 프로필에서 사용 |
| `LINE_CLIENT_ID` / `LINE_CLIENT_SECRET` | LINE 로그인 | 발급 전엔 `app.auth.social.line.enabled=false` 유지 |
| `KAKAO_CLIENT_ID` / `KAKAO_CLIENT_SECRET` | 카카오 로그인 | 〃 |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | 구글 로그인 | 〃 |
| `APP_STORAGE_BUCKET` | S3 버킷명 | `app.storage.type=s3`일 때만 |
| `REDIS_HOST` / `REDIS_PORT` | Redis 접속 정보 | `app.redis.enabled=true`일 때만 |

## 6. 빌드 및 실행

```bash
# server/ 디렉터리에서
gradle build                                      # 컴파일 + 테스트 + bootJar 패키징
gradle bootRun --args='--spring.profiles.active=local'   # 개발 서버 기동
# 또는
SPRING_PROFILES_ACTIVE=local gradle bootRun
```

wrapper를 생성했다면 `gradle` 대신 `./gradlew`(또는 `gradlew.bat`)를 그대로 사용하면 됩니다.

기본 포트: `8080`. 로컬 프로필은 Redis 비활성(`app.redis.enabled=false`), 파일 스토리지는 로컬 디스크(`server/uploads/`)를 사용합니다.

**기동 확인**: 콘솔에 `Started ServerApplication in N seconds`가 뜨면 정상. 인증 없이 호출 가능한 엔드포인트로 빠르게 확인:
```bash
curl http://localhost:8080/system/gate
# {"open":true,"nextOpenAt":"..."} 형태 응답이면 정상 기동
```

## 7. 자주 겪는 문제

| 증상 | 원인 / 해결 |
|------|-----------|
| `Dependency requires at least JVM runtime version 17` | Gradle을 실행 중인 JVM이 17 미만 — `JAVA_HOME`을 17+ 로 재설정 후 재시도 |
| 기동 시 `Communications link failure` / DB 연결 실패 | MariaDB가 안 떠 있거나 포트/계정 불일치 — 3번 섹션 재확인 |
| Flyway가 `Validate failed` 에러 | 이전에 다른 스키마로 DB를 만들어 둔 경우 — 개발 중이면 DB를 지우고(`DROP DATABASE moonlighttalk; CREATE DATABASE ...`) 재기동 |
| 소셜 로그인 호출 시 `PROVIDER_DISABLED` | 해당 provider의 `enabled`가 `false` — 키 발급 후 `application-*.yml`에서 `enabled: true` + client-id/secret 설정 |

## 현재 구현 범위

**완료**
- DB 스키마(`V1__init_schema.sql`) — [02 문서](../docs/02-db-schema.md) 전체 반영
- 공통 인프라: 에러 응답(`common/response`, `common/exception`), JWT 인증(HandlerInterceptor 기반, Spring Security 미사용 — [05 §11](../docs/05-server-structure.md)), CORS(전체 오픈, [05 §10](../docs/05-server-structure.md)), 파일 스토리지 추상화(S3/로컬, [05 §8](../docs/05-server-structure.md)), Redis 선택 구성 예시(`presence/`)
- 인증 도메인: 소셜 로그인(LINE/KAKAO/GOOGLE 실 구현 + provider별 enabled 설정, [05 §9.1](../docs/05-server-structure.md)), 토큰 갱신, 시스템 게이트(`/system/gate`)
- 프로필/온보딩 도메인: 닉네임 검증, 프로필 생성, `GET /me`/`GET /users/:id/profile`, 프로필 사진 업로드/등록, 관심사·소개·지역 수정

**아직 구현 안 됨** (다음 단계)
- 오늘의 포스트(`post`), 달빛가든 피드/댓글/번역(`garden`), 대화 신청·대화방·WebSocket 채팅(`chat`), 친구(`friend`), 신고·차단(`moderation`), 루나(`luna`), 스케줄러(`scheduler`) 배치

**설정이 필요한 항목**
- `app.jwt.secret` — 운영 배포 전 반드시 환경변수로 교체(현재 local 프로필 기본값은 개발용 더미)
- 소셜 로그인 각 provider의 `client-id`/`client-secret` — 발급 전까지 `enabled: false` 유지
- `app.storage.type=s3` 전환 시 `app.storage.bucket` 필수
