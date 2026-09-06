# tools — 검증·기획서 도구

> 여기 있는 것은 **앱이 쓰는 코드가 아니다.** 규칙이 정말 그대로 도는지 확인하는 도구다.
>
> 왜 저장소에 두는가: 예전에는 이런 스크립트를 `scratchpad/`에 두고 커밋하지 않았다.
> 그래서 다른 기기가 받으면 **문서만 스크립트를 가리키고 실물은 없었다**
> (`docs/09`에 *"`verify_garden.py`는 저장소에 없다"* 는 하소연이 남아 있었다).
> 규칙을 확인하는 방법은 규칙만큼 오래 남아야 한다.

## verify/ — 규칙이 그대로 도는가

로컬 스택이 떠 있어야 한다(`docs/07` §2-2 루틴):
MariaDB 기동 → `cd server && ./gradlew bootRun --args='--spring.profiles.active=local'`.

```bash
python tools/verify/verify_moderation.py
python tools/verify/verify_feed_block_page2.py
```

| 파일 | 무엇을 지키는가 |
|---|---|
| `verify_moderation.py` | 받은 신청 **14일 무응답 만료**(대화·친구) · **만료 ≠ 거절**(만료 뒤 재신청 가능) · 신고·차단이 **양방향으로** 신청을 닫는다 · 차단당한 쪽 가든·[포스트 정보]에서도 사라진다 |
| `verify_feed_block_page2.py` | 🚨 **순서가 정해진 뒤 차단해도 2페이지에서 사라지는가.** 첫 페이지만 보는 검사로는 절대 못 잡는 회귀다 |
| `_common.py` | 목 로그인 · SQL · 검사 집계 |

**local 프로필에서만 돈다** — 목 로그인(`app.auth.social.mock.enabled`)과 배치 수동 실행
(`app.scheduler.dev-trigger-enabled`)이 켜져 있어야 한다. 운영에서는 둘 다 꺼져 있다.

접속 정보는 환경변수로 바꿀 수 있다:
`VERIFY_BASE` · `VERIFY_MYSQL` · `VERIFY_DB_USER` · `VERIFY_DB_PASS` · `VERIFY_DB_NAME`.

### 🚨 이 검사들을 쓸 때 조심할 것

- **배치는 개발 DB 전체를 본다.** 만료 건수를 `==`로 세면 남의 오래된 신청이 함께 정리되며
  틀린다 — `>=`로 볼 것(함정 #61).
- **가든은 한 페이지만 보면 안 된다.** 오늘 공유한 사람이 여럿이면 찾는 사람이 2페이지로 밀려
  **버그가 없는데도 실패**한다. `verify_moderation.py`의 `garden_of()`는 끝까지 훑는다.
- **18시가 지나면 후보가 빈다**(그날 공유한 사람이 아직 없어서다). 스크립트가
  `publish_post()`로 직접 만들어 두므로 시간과 무관하게 돈다.

## spec/ — 기획서 비교

```bash
# 본문 전체 비교 (달라진 줄이 곧 할 일이다)
python tools/spec/diff_docx_text.py "<옛 기획서.docx>" "<새 기획서.docx>"

# 어느 화면 그림이 교체됐는가
python tools/spec/diff_docx_text.py "<옛.docx>" "<새.docx>" --media

# 본문만 뽑기
python tools/spec/diff_docx_text.py "<기획서.docx>" --dump out.txt
```

🚨 **기획서를 새로 받으면 화면·이미지만 보지 말 것.**
`260906`판에서 **아홉 줄**이 달라졌는데, 화면 위주로 본 세션은 **네 줄로 기록**했고
6-1·6-2에 조용히 늘어난 다섯 줄(**받은 신청 14일 만료**, 신고·차단 시 목록 삭제)을 놓쳤다.
이 도구면 몇 초다. 정본은 **Plan_4 폴더에서 가장 최근 파일**이다(파일명이 계속 바뀐다).
