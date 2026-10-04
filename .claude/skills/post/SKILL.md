---
name: post
description: 이 세션을 달빛톡 '포스트' 콘텐츠 전담으로 설정한다 — 기획서 3장, D:\Plan_Chat\UI\Scene_Post 위주. 사용자가 /post를 입력할 때만 쓴다.
disable-model-invocation: true
---

# 📸 포스트 세션

이 세션은 이제 **포스트** 담당이다. 이후 요청은 별말 없으면 포스트 기준으로 해석한다.

**먼저 `.claude/content-sessions.md`를 읽고 그 §2 시작 절차를 따른다** — 특히 §4 동시 작업 규칙.
(가능하면 세션 제목을 `📸 포스트`로 바꿔 둔다.)

명령 뒤에 덧붙인 말이 있으면 그것이 첫 작업이다: $ARGUMENTS

## 담당 범위

| | 어디 |
|---|---|
| 기획서 | **3장** 포스트 등록(3-1 오늘의 포스트 등록창 · 3-2 등록 프로세스) |
| UI | **`D:\Plan_Chat\UI\Scene_Post\`** (+ `Example/` 시안). 하단 주메뉴·상단 버튼은 `Scene_Garden` |
| 에셋 | `assets/images/scene_post/` (+ `ja/`) |
| 클라 | `lib/features/post/` — 화면은 **`home_screen.dart`**(이름이 home이다), 그림 좌표 `post_art.dart` |
| 서버 | `server/.../post/` · `db/migration` V11(메인 사진·9장·삭제 3회) |
| 문서 | `01` post API · `02` `posts`/`post_photos` · `08` §0-1(일본어판 #1·#7~9) · `13` 포스트 화면 |
| 인접 | 부스트 화면 `store/presentation/screens/boost_screen.dart`(상점은 "그 외" 몫 — 버튼만 포스트에 있다) |

## 이미 정해진 것

- 🚨 **포스트 화면은 스크롤하지 않는다** — 카드가 남은 높이에 정확히 들어차므로 `NeverScrollableScrollPhysics`.
  그래서 **당겨서 새로고침도 없다**(실기기에서 "울렁" 잡힌 것, 함정 #79)
- 영업일은 **KST 18시** 기준(게이트는 폐지됨). 메인 사진이 첫 장, 최대 9장, 삭제 3회
- `back_nopost_kor`/`_jap`은 **언어별 빈 상태 그림**이다(국가 아님) → 원문은 그대로, 일본어는 `ja/`
- 🚨 **공유 뒤 사진을 다 지운 포스트**는 가든 후보에서 빠진다(`EXISTS post_photos`) — 사진 삭제 흐름을 바꾸면 가든 세션에 알릴 것

## 알아둘 것

- 일본어판 그림 대기 4장: `title_post` · `button_postalbum` · `button_boost` · `button_postmake`(08 §0-1)
- 18시가 지나면 그날 공유한 사람이 없어 가든이 비는 것은 정상 — 검증용 공유는 `tools/verify/_common.py`의 `publish_post()`
