---
name: garden
description: 이 세션을 달빛톡 '달빛가든' 콘텐츠 전담으로 설정한다 — 기획서 4장(피드·댓글·대화 신청)과 8장(달빛 한마디), D:\Plan_Chat\UI\Scene_Garden 위주. 사용자가 /garden을 입력할 때만 쓴다.
disable-model-invocation: true
---

# 🌙 달빛가든 세션

이 세션은 이제 **달빛가든** 담당이다. 이후 요청은 별말 없으면 달빛가든 기준으로 해석한다.

**먼저 `.claude/content-sessions.md`를 읽고 그 §2 시작 절차를 따른다** — 특히 §4 동시 작업 규칙.
(가능하면 세션 제목을 `🌙 달빛가든`으로 바꿔 둔다.)

명령 뒤에 덧붙인 말이 있으면 그것이 첫 작업이다: $ARGUMENTS

## 담당 범위

| | 어디 |
|---|---|
| 기획서 | **4장**(4-1 피드창 · 4-2 포스트 댓글 · 4-3 대화 신청) + **8장** 달빛 한마디(8-1~8-3) |
| UI | **`D:\Plan_Chat\UI\Scene_Garden\`** (+ `Example/`). ⚠️ 이 폴더에는 **하단 주메뉴·Prime·루나 그림**도 들어 있다 — 그건 모든 탭이 쓰는 공용이다 |
| 에셋 | `assets/images/scene_garden/` (+ `ja/`) |
| 클라 | `lib/features/garden/`(피드 `garden_screen.dart` · 댓글 `comments_sheet.dart` · `garden_art.dart`) · `lib/features/daily/`(달빛 한마디) |
| 서버 | `server/.../garden/`(+`translate/`) · `comment/` · `dailyquestion/` |
| 공용 | 4-3 대화 신청 창 `chat/.../chat_request_dialog.dart`(대화방과 공용) · [포스트 정보] `postinfo/` |
| 검증 | `tools/verify/verify_feed_block_page2.py` · `verify_moderation.py` |
| 문서 | `01` garden·comment·daily API · `02` · `08` §0-1(#2~6·#10)·§0-2(관심사) · `09` §4-1(봇) · `13` |

## 이미 정해진 것

- 🤖 **빈 피드는 배경만** — 빈 상태 화면·문구를 만들지 않는다. **봇 데이터가 채울 예정**(09 §4-1).
  봇이 무산되면 이 결정부터 되돌린다(`gardenEmptyTitle`/`Detail`은 ARB에 남아 있다)
- 🚨 **사진 0장 포스트는 후보에서 뺀다** — `EXISTS (post_photos)`가 `selectFeedCandidates`와 `selectCandidatesByIds` **두 쿼리 모두**에 있어야 한다
- 🚨 **차단은 캐시된 순서에도 먹어야 한다** — 순서는 진입 때 한 번 정하고 스크롤은 `selectCandidatesByIds`를 타므로
  거기서도 걸러야 한다. **첫 페이지만 보는 검사로는 못 잡는다**(`verify_feed_block_page2.py`)
- 열람 제한(무료는 메인 1장)은 **서버가** 건다 — [포스트 정보]도 같은 판정 `canViewAllPhotos` 하나
- 필터 칩 `_kor`/`_jap`은 **UI 언어가 아니라 고른 나라**다(언어별 그림과 헷갈리지 말 것)
- 대화 신청 한마디 **100자, 코드포인트로 센다** — Flutter `maxLength` 금지(`request_message_input.dart`)
- 일본어 탭 라벨 두 장(「月光ガーデン」「プロフィール」)은 칸보다 넓어 **84%로 줄여 그린다** — 규격 재요청은 더 나빠진다

## 알아둘 것

- 관심사 칩 그림은 **`Interest_movie` 한 장뿐** — 나머지는 자리 칩(08 §0-2)
- 확인은 **무료 계정으로**(앨범패스·프라임은 열람 제한이 안 걸린다). 15분 안에 본 상대는 다시 안 나온다
  → `DELETE FROM feed_exposures WHERE user_id='<보는 사람>';`
