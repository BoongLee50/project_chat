---
name: friend
description: 이 세션을 달빛톡 '친구' 콘텐츠 전담으로 설정한다 — 기획서 7장 친구관리(친구 목록·받은 친구 신청)와 5-1 친구 신청, D:\Plan_Chat\UI\Scene_Friend 위주. 사용자가 /friend를 입력할 때만 쓴다.
disable-model-invocation: true
---

# 🤝 친구 세션

이 세션은 이제 **친구** 담당이다. 이후 요청은 별말 없으면 친구 기준으로 해석한다.

**먼저 `.claude/content-sessions.md`를 읽고 그 §2 시작 절차를 따른다** — 특히 §4 동시 작업 규칙.
(가능하면 세션 제목을 `🤝 친구`로 바꿔 둔다.)

명령 뒤에 덧붙인 말이 있으면 그것이 첫 작업이다: $ARGUMENTS

## 담당 범위

| | 어디 |
|---|---|
| 기획서 | **7장 친구관리**(7-1 친구 목록 · 7-2 받은 친구 신청) + **5-1** 친구 신청(채팅창에서 거는 규칙) |
| UI | **`D:\Plan_Chat\UI\Scene_Friend\`** — `Friend List/` · `Application Received/`. ⚠️ `[받은 신청]` 탭 그림은 **`Scene_Talk`의 것**을 쓴다 |
| 에셋 | `assets/images/scene_friend/friend_list/` · `application_received/` |
| 클라 | `lib/features/friend/` — 목록 `friends_screen.dart` · `friend_post_screen.dart`([친구 포스트 정보]) · `friend_request_screen.dart`([친구 요청 상세]) · 좌표 `friend_art.dart` · 신청 창 `friend_request_dialog.dart` |
| 서버 | `server/.../friend/` — 순서 `FriendService.FRIEND_ORDER` · `db/migration` V27 |
| 검증·데모 | `tools/verify/verify_friend.py`(26건) · `tools/demo/demo_friend.sql`(먼저 `tools/demo/make_seed_photos.py`) |
| 문서 | `01` friend API · `02` `friendships` · `08` §0-1(#18~21) · `07` §4 2026-09-19(9) · `09` §3-0-F |

🚨 **대화방 세션과 같이 쓰는 조각** — 받은 신청 셀·팝업은 `chat/presentation/widgets/talk_cell.dart`·`request_popup.dart`를
**그대로** 쓴다(수락 버튼 그림 `button_acceptfriend`만 다르다). 거기를 고치면 **대화방 팝업도 바뀐다** — 고쳤으면 보고에 적을 것.

## 이미 정해진 것 (되돌리지 말 것)

- **목록 순서는 서버가 정한다**: 고정(늦게 고정한 것 위) > 신규(수락 7일) > 온라인 > 최근 접속. **앱에서 다시 정렬하지 말 것**
- 🚨 **고정은 보는 사람마다 따로** — `friendships` 한 행을 둘이 같이 써서 칼럼이 둘(`requester_pinned_at`/`addressee_pinned_at`, 함정 #86).
  끊었다 다시 친구가 되면 **옛 고정은 없다**(행을 지우므로)
- 남의 관계 고정은 403, 대기 중 신청 고정은 409
- 받은 친구 신청 `N` = 안 열어 본 것(V27 `viewed_at`) — **받는 사람이 [포스트 정보]를 열 때만** 찍힌다
- 친구 신청 한마디 **100자, 코드포인트**(대화 신청과 통일)
- 친구 신청 만료는 **대화 신청과 같은 14일**로 뒀다(`app.friend.request-expire-days`). 만료는 **행 삭제**(pair_key UNIQUE 때문)

## 알아둘 것 (기획 확인·그림 대기)

- [친구 관리] 메뉴 **아이콘 다섯은 그림이 안 왔다** → `Icons.*`는 자리 표시일 뿐
- 핀과 `N`이 **같은 자리** — 고정한 신규 친구는 핀만 보인다(확인 대기)
- 친구 카드 도시 표기 — 시안은 소문자 영문(`seoul`), 지금은 언어별 도시명
- 일본어판 그림 대기 4장: `title_friends` · `button_friends_color/normal` · `button_management`. `scene_friend/ja/` 폴더·`pubspec.yaml` 줄은 **아직 없다** — 오면 폴더 선언부터 넣고 완전 재빌드
