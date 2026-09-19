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
python tools/verify/verify_talk_room.py
python tools/verify/verify_friend.py
```

| 파일 | 무엇을 지키는가 |
|---|---|
| `verify_moderation.py` | 받은 신청 **14일 무응답 만료**(대화·친구) · **만료 ≠ 거절**(만료 뒤 재신청 가능) · 신고·차단이 **양방향으로** 신청을 닫는다 · 차단당한 쪽 가든·[포스트 정보]에서도 사라진다 |
| `verify_feed_block_page2.py` | 🚨 **순서가 정해진 뒤 차단해도 2페이지에서 사라지는가.** 첫 페이지만 보는 검사로는 절대 못 잡는 회귀다 |
| `verify_talk_room.py` | 대화방 개편(V26): 신청 한마디 **100자**(대화·친구) · 이모지·공백을 **코드포인트**로 · 줄바꿈 → 공백 · 받은 신청 `viewed`(받는 사람만 찍힘) · 미리보기는 마지막 **글**·시각은 마지막 **메시지** · 받은 신청 번역 **무료** |
| `verify_friend.py` | 친구 개편(V27): 목록 순서 **고정 > 신규 7일 > (온라인) > 최근 접속** · 7일 경계 · 🚨 **고정은 보는 사람마다 따로** · pin/unpin(남의 관계 403 · 대기 중 409) · **끊었다 다시 친구 → 옛 고정 없음** · 받은 친구 신청 `viewed`(받는 사람만 찍힘) |
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

## spec/ — 전달본 리소스 비교

```bash
python tools/spec/compare_ui_delivery.py                  # 기본: D:/MyProject/Plan_Chat/UI
python tools/spec/compare_ui_delivery.py "D:/Plan_Chat/UI" # 다른 기기
```

🚨 **기획은 같은 이름으로 내용만 살짝 바꿔 보내기도 한다.** "그 해시가 에셋 어딘가에 있나"로는
못 잡는다 — 이 도구는 **같은 이름끼리** 맞대서 `같음` / `🔴 이름 같고 다름`(규격·바뀐 영역) /
`🆕 새 그림` / `저장소에만`으로 나눈다. 이름 규칙(`_jap`→`ja/`, `_kor`→원문, 공백→밑줄)은
09-14 들여오기와 같다. 새 전달본을 받으면 **들이기 전에 먼저** 돌릴 것.

⚠️ 픽셀 비교는 `getbbox(alpha_only=False)`로 한다 — 기본값은 RGBA에서 **알파만** 봐서
색만 바뀐 그림을 "픽셀 동일"로 잘못 말한다(만들다가 실제로 걸렸다).

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
이 도구면 몇 초다. 정본은 **`D:\Plan_Chat\기획서\`에서 가장 최근 `.docx`** + 같은 날의
**`YYYY-MM-DD 기획사항.txt`**(기획서보다 우선)다. 파일명이 계속 바뀐다 —
`수정2` → `260906` → `260919`. 리소스 전달본은 `D:\Plan_Chat\UI\`.
⚠️ `기획사항.txt`는 **CP949(윈도우 한글)** 로 온다 — `iconv -f cp949 -t utf-8`로 읽을 것.

## demo/ — 화면을 눈으로 보기 위한 데이터

| 파일 | 무엇 |
|---|---|
| `demo/demo_talk.sql` | 대화방 UI 확인용. **[LINE] 목 로그인 계정**에게 대화 3칸(안 읽음 `N` · 일본어 글 · 음성 뒤 글 미리보기 · 사진 없는 빈 칸) + 받은 신청 2칸(안 열어 본 일본어 · 열어 본 한국어). 전부 `demo-` 접두어, 다시 돌리면 먼저 비운다 |
| `demo/demo_friend.sql` | 친구 화면 확인용. 같은 계정에게 친구 5(고정 1 · 신규 `N` 1 · 접속 시각 셋 · 사진 없음 1 · 일본어 소개) + 받은 친구 신청 2(안 열어 봄 · 열어 본 일본어). 전부 `demo-f` 접두어. 수락해 보며 생긴 친구 대화방까지 CLEANUP이 지운다 |
| `demo/make_seed_photos.py` | 두 데모가 쓰는 사진 3장(`uploads/seed/p1~p3`)을 만든다 — 밤하늘+달 그림. **기기마다 한 번** |

```bash
python tools/demo/make_seed_photos.py   # 사진이 없을 때 한 번
mysql -umoonlighttalk -pmoonlighttalk moonlighttalk --default-character-set=utf8mb4 < tools/demo/demo_talk.sql
mysql -umoonlighttalk -pmoonlighttalk moonlighttalk --default-character-set=utf8mb4 < tools/demo/demo_friend.sql
```

⚠️ 검증(`verify/`)과 달리 **일부러 남겨 두는 데이터**다. 다 봤으면 파일 맨 위 CLEANUP 블록만 돌려 지울 것.
사진은 `server/server/uploads/seed/`를 쓰는데 이 폴더는 저장소에 없다(gitignore) — 없으면 사진 칸만 빈다. `make_seed_photos.py`로 만들 것.
