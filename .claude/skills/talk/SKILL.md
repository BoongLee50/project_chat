---
name: talk
description: 이 세션을 달빛톡 '대화방' 콘텐츠 전담으로 설정한다 — 기획서 6장(대화 목록·받은 신청)과 5장(채팅창), D:\Plan_Chat\UI\Scene_Talk 위주. 사용자가 /talk를 입력할 때만 쓴다.
disable-model-invocation: true
---

# 💬 대화방 세션

이 세션은 이제 **대화방**(+채팅창) 담당이다. 이후 요청은 별말 없으면 대화방 기준으로 해석한다.

**먼저 `.claude/content-sessions.md`를 읽고 그 §2 시작 절차를 따른다** — 특히 §4 동시 작업 규칙.
(가능하면 세션 제목을 `💬 대화방`으로 바꿔 둔다.)

명령 뒤에 덧붙인 말이 있으면 그것이 첫 작업이다: $ARGUMENTS

## 담당 범위

| | 어디 |
|---|---|
| 기획서 | **6장**(6-1 대화 목록 · 6-2 받은 신청) + **5장** 채팅창(5-1 친구 신청의 *버튼 자리*까지. 친구 신청 규칙은 친구 세션) |
| UI | **`D:\Plan_Chat\UI\Scene_Talk\`** — `Talk List/` · `Application Received/` (+ `Example/`) |
| 에셋 | `assets/images/scene_talk/talk_list/` · `application_received/` |
| 클라 | `lib/features/chat/` — 목록 `chat_rooms_screen.dart` · 받은 신청 `received_request_screen.dart` · 채팅창 `chat_screen.dart` · 좌표 `talk_art.dart` · 음성·이모지 |
| 서버 | `server/.../chat/`(+`socket/` WebSocket) |
| 검증·데모 | `tools/verify/verify_talk_room.py`(23건) · `tools/demo/demo_talk.sql` |
| 문서 | `01` chat API · `02` `chat_*` · `08` §0-1(#11~17) · `07` §4 2026-09-19(6)(기획사항 원문·충돌 결정표) |

🚨 **친구 세션과 같이 쓰는 조각** — `talk_cell.dart`(`TalkCell`·`CellGrid`·`ArtTabs`)와
`request_popup.dart`(`PopupPhotoArea`·`PopupPanel`·`PopupDecideRow`)는 **친구 목록 받은 신청·친구 요청 상세가 그대로 쓴다.**
여기를 고치면 **팝업 세 개가 함께 바뀐다** — 고쳤으면 보고에 적을 것.

## 이미 정해진 것 (되돌리지 말 것)

- 🚫 **`icon_next` 화살표는 쓰지 않는다** — *"뒤로가기 말고는 대화방에는 화살표가 없음!"* 에셋으로 들이지도 않았다.
  전달본 대조에서 계속 🆕로 보이는 것은 정상
- 🚨 **셀을 누르면 확인창 없이 바로 채팅창** — 기획서 6-1의 *"대화방으로 이동할까요?"* 는 **지워질 문장**이다. 되살리지 말 것
- 🚨 **받은 신청 팝업은 스크롤하지 않는다** — 사진 칸이 남는 높이를 먹는다(함정 #85)
- 셀 = 2열 카드(`frame_list` 504×522), 사진은 **상대 프로필 사진**, 글 25자+`…`, 시각은 30일 넘으면 숨김
- **미리보기는 마지막 "글", 시각은 마지막 "메시지"**(음성이 마지막이어도)
- 받은 신청 `N` = 아직 안 열어 본 신청(V26 `viewed_at`) — **받는 사람이 열 때만** 찍힌다
- 신청 한마디 **100자, 코드포인트** · 받은 신청 번역은 **무조건 무료**(scope `REQUEST`)
- 대화방 수명 **30일 무대화 → `ENDED`**(친구 방도 예외 없음, 무료 번역 자리는 평생 5개 — 돌아오지 않는다)
- 받은 신청 **14일 무응답 → `EXPIRED`**(거절과 다르다 — 재신청 금지가 안 붙는다)

## 알아둘 것

- **채팅창(5장)은 아직 새 리소스가 안 왔다** — `Scene_Talk`에는 목록·받은 신청 둘뿐. 오면 09가 말한 "다음 작업"이 이것이다
- 🚨 **받은 신청에서 신고·차단할 길이 없다**(새 시안에 메뉴가 없음) — 폐지인지 기획 확인 대기(`10` §0-2)
- `[원문보기]`는 번역문이 원문과 다를 때만 보인다 → 개발 중엔 안 보인다. 보려면 `APP_TRANSLATE_PROVIDER=mock`으로 서버 기동
- 실기기 소켓은 `adb reverse tcp:8080 tcp:8080` + `--dart-define=API_BASE_URL=http://localhost:8080`
