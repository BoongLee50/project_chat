# 달빛톡 (夜談)

한·일 사진 중심 매칭 커뮤니티 앱. **24시간 운영**, 하루(영업일)는 **KST 18:00**에 바뀐다
(옛 "밤에만 열리는 게이트"는 Plan_3에서 폐지 — V10).

**모노레포**: `lib/` Flutter 클라이언트 · `server/` Spring Boot 서버 · `docs/` 설계 문서 · `tools/` 검증·대조 스크립트

---

## 처음 여는 사람(또는 새 작업 세션·다른 계정)은 여기부터

1. 👉 **[.claude/content-sessions.md](.claude/content-sessions.md)** — **공통 규칙**. 콘텐츠별 아홉 세션 · 여러 기기·계정이 한 저장소를 함께 쓰는 법 · 커밋 규칙
2. 👉 **[docs/07-work-log.md](docs/07-work-log.md)** §1 — 현재 상태 · 재개 절차 · 함정 · 세션 로그
3. 👉 **[docs/09-next-task-handoff.md](docs/09-next-task-handoff.md)** §0 — 콘텐츠별 다음 할 일 (세션마다 **자기 줄**)

그 다음 필요에 따라:

| 문서 | 내용 |
|------|------|
| [01 API 명세](docs/01-protocol-api-spec.md) | REST / WebSocket 계약 |
| [02 DB 스키마](docs/02-db-schema.md) | MariaDB + Redis(선택) |
| [03 Flutter 구조](docs/03-flutter-structure.md) | 클라이언트 구조 |
| [04 로드맵](docs/04-progress-and-roadmap.md) | 진행 현황 · 남은 작업 · 미결정 |
| [05 서버 구조](docs/05-server-structure.md) | Spring Boot 구조 |
| [06 개발환경](docs/06-dev-environment-setup.md) | 기기별 최초 세팅 |
| [08 리소스](docs/08-assets-checklist.md) | 그림 목록 · 규격 · 남은 그림 |
| [10 기획 확인](docs/10-open-questions.md) | 기획에 물어볼 것 |
| [14 UI 대전제](docs/14-ui-ground-rules.md) | 🚨 UI 작업 전 필독 |

> **기획 자료는 저장소 밖에 있다** (기기마다 자리가 다르다):
> - 이 PC: 기획서 `D:\Plan_Chat\기획서\`(가장 최근 `.docx`가 정본) · 그래픽 `D:\Plan_Chat\그래픽 소스\`
> - 다른 기기: `D:\MyProject\Plan_Chat\…`
> - 믿는 순서: **대화 중 사용자 결정 > `기획사항.txt` > 기획서 `.docx` > 이미지**

---

## 빠른 실행

```bash
# 1) DB (최초 세팅 절차는 docs/06 참고)
<MariaDB>/bin/mariadbd.exe --datadir="<데이터경로>" --port=3306 --console

# 2) 서버 (JDK 17 필요, Gradle은 래퍼 사용 — 띄울 때 Flyway 마이그레이션이 적용된다)
cd server && JAVA_HOME="<jdk17>" ./gradlew bootRun

# 3) 앱
flutter pub get
flutter gen-l10n
flutter run -d emulator-5554
```

- 서버 확인: `curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:8080/auth/social` → **400**이면 정상
  (옛 `/system/gate`는 지워진 경로라 401이 온다 — 07 함정 #57)
- 에뮬레이터에서 호스트 서버 주소는 **`http://10.0.2.2:8080`** (localhost 아님). 소켓·실기기는 `adb reverse` + `--dart-define` (07 §2)
- 소셜 키가 아직 없어 **개발용 목 로그인** 사용 — 로그인 버튼별로 다른 테스트 계정이 생성됨

## 기술 스택

| | |
|---|---|
| 클라이언트 | Flutter(stable) · Riverpod · go_router · Dio · flutter_secure_storage |
| 서버 | Spring Boot 3.3 · MyBatis · Flyway · JWT(jjwt) · WebSocket · JDK 17 |
| DB | MariaDB 11.4 (Redis는 선택 구성) |
