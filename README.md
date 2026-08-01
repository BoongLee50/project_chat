# 달빛톡 (夜談)

밤에만 열리는 한·일 사진 중심 매칭 커뮤니티 앱. **KST 17:00 개방 ~ 다음날 06:00 종료**
(친구 목록·친구 대화는 24시간).

**모노레포**: `lib/` Flutter 클라이언트 · `server/` Spring Boot 서버 · `docs/` 설계 문서

---

## 처음 여는 사람(또는 새 작업 세션)은 여기부터

👉 **[docs/07-work-log.md](docs/07-work-log.md)** — 현재 상태 · 재개 절차 · 함정 · 세션 로그

그 다음 필요에 따라:

| 문서 | 내용 |
|------|------|
| [01 API 명세](docs/01-protocol-api-spec.md) | REST / WebSocket 계약 |
| [02 DB 스키마](docs/02-db-schema.md) | MariaDB + Redis(선택) |
| [03 Flutter 구조](docs/03-flutter-structure.md) | 클라이언트 구조 |
| [04 로드맵](docs/04-progress-and-roadmap.md) | 진행 현황 · 남은 작업 · 미결정 |
| [05 서버 구조](docs/05-server-structure.md) | Spring Boot 구조 |
| [06 개발환경](docs/06-dev-environment-setup.md) | 기기별 최초 세팅 |

> 기획서 원본은 저장소 밖에 있음: `D:\MyProject\Plan_Chat\Plan_2` (현행) / `Plan_1`(구버전)

---

## 빠른 실행

```bash
# 1) DB (최초 세팅 절차는 docs/06 참고)
<MariaDB>/bin/mariadbd.exe --datadir="<데이터경로>" --port=3306 --console

# 2) 서버 (JDK 17 필요, Gradle은 래퍼 사용)
cd server && JAVA_HOME="<jdk17>" ./gradlew bootRun

# 3) 앱
flutter pub get
flutter run -d emulator-5554
```

- 서버 확인: `curl http://localhost:8080/system/gate`
- 에뮬레이터에서 호스트 서버 주소는 **`http://10.0.2.2:8080`** (localhost 아님)
- 소셜 키가 아직 없어 **개발용 목 로그인** 사용 — 로그인 버튼별로 다른 테스트 계정이 생성됨

## 기술 스택

| | |
|---|---|
| 클라이언트 | Flutter(stable) · Riverpod · go_router · Dio · flutter_secure_storage |
| 서버 | Spring Boot 3.3 · MyBatis · Flyway · JWT(jjwt) · WebSocket · JDK 17 |
| DB | MariaDB 11.4 (Redis는 선택 구성) |
