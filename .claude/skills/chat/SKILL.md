---
name: chat
description: 이 세션을 달빛톡 '채팅창' 콘텐츠 전담으로 설정한다 — 기획서 261011 5장 채팅창(메시지·이모지·GIF·음성·채팅 관리 패널), D:\Plan_Chat\UI\Scene_Chat 위주. 사용자가 /chat을 입력할 때만 쓴다.
disable-model-invocation: true
---

# 💌 채팅창 세션

이 세션은 이제 **채팅창**(1:1 대화 화면) 담당이다. 이후 요청은 별말 없으면 채팅창 기준으로 해석한다.

**먼저 `.claude/content-sessions.md`를 읽고 그 §2 시작 절차를 따른다** — 특히 §4 동시 작업 규칙.
(가능하면 세션 제목을 `💌 채팅창`으로 바꿔 둔다.)

명령 뒤에 덧붙인 말이 있으면 그것이 첫 작업이다: $ARGUMENTS

## 담당 범위

| | 어디 |
|---|---|
| 기획서 | 261011 **5장 채팅창**. ⚠️ 이 기획서는 **완전 최신이 아닐 수 있다**(사용자 2026-10-25) — 대화 중 결정이 더 우선. 5-1 친구 신청은 **규칙은 `/friend`, 채팅창 안 버튼·팝업 자리는 여기** |
| UI | **`D:\Plan_Chat\UI\Scene_Chat\`** (그림 19장 + `Example/` 3장, 2026-10-25 첫 전달 — ✅ 반영) — 좌표는 `Example/채팅창 좌표값.png`, 시안 `Example/채팅창 참고 화면.png`·`참고화면.png` |
| 에셋 | `assets/images/scene_chat/`(19장, `pubspec.yaml` 한 줄) · 상수 **`ChatArt`**(`widgets/chat_art.dart`) · 현황 `08` §0-5. 새 전달본은 먼저 `python tools/spec/compare_ui_delivery.py "D:/Plan_Chat/UI"` |
| 클라 | `lib/features/chat/` 중 **채팅창 쪽** — `screens/chat_screen.dart` · `widgets/chat_art.dart` · `widgets/voice_message.dart` · `providers/voice_recorder.dart`·`voice_player.dart` |
| 서버 | `server/.../chat/` 중 **메시지 쪽** — `socket/`(WebSocket) · 메시지·음성 업로드·읽음 · 번역 자리 `translate_rooms` |
| 문서 | `01` §1.6 대화방(메시지·음성) · §2 WebSocket · `02` `chat_messages`·`translate_rooms` · `08`(새 절로) · `13` |

🚨 **`lib/features/chat/` 폴더를 `/talk`(대화방)와 나눠 쓴다** — 대화 목록·받은 신청(`chat_rooms_screen.dart` · `received_request_screen.dart` ·
`talk_cell.dart` · `request_popup.dart` · `talk_art.dart`)은 **`/talk` 몫**이다. `chat_provider.dart` · `chat_api.dart` · `chat_models.dart`와
서버 `chat/` 패키지(방·신청 ↔ 메시지·소켓)는 **둘이 같이 쓴다** — 고치면 보고에 적을 것.

그 밖에 걸친 것:
- **[프로필 보기]** `postinfo/.../profile_view_screen.dart`(프로필 세션 몫) — 채팅창에서 열면 하단 버튼이 **[친구 신청]**(`profileViewActionOf()`)
- **신고·차단** `moderation/` 대화상자(공용) · **[번역 패스]** → 자동 번역 구매 화면(`/shop` 몫, 공용 `shared/widgets/translate_pass_button.dart`)

## 기획서 5장 요지 (본문이 정본 — 바뀌었으면 본문을 따른다)

- 진입: 대화 신청 수락 · 대화방 [대화] 목록. **확인창 없이 바로 들어온다**(`/talk` 결정)
- **번역**: 채팅창 **5개까지 무료**(닫기 전까지 계속) — 🚨 **자리는 평생 5개, 방이 닫혀도 돌아오지 않는다**. 다 쓴 뒤 새 방에 들어가면 하단 안내
  *"무료 번역을 모두 사용했어요. PRIME 구독 시 모든 대화에서 자동 번역을 이용할 수 있어요."* · Prime·자동번역 패스는 무제한
- **입력**: 텍스트 · 이모지(**폰 기본 이모지 패널**) · GIF(KLIPY·Tenor 등 무료 검색 API, 고르면 확인 없이 바로 전송) · 음성
- 입력부: 글을 치면 [음성] 버튼이 [보내기]로 바뀜
- **음성**: 누르면 녹음 → [정지]로 바뀜 · **최대 30초**(넘으면 자동 정지) · 녹음 중 실시간 파형(안 되면 그림) ·
  정지 후 [보내기] + [녹음 재생] + [녹음 삭제](삭제하면 기본으로) · **계정당 5회 무료, 초기화 안 됨** → 다 쓰면
  *"무료 음성 메시지를 모두 사용했어요. PRIME 구독 시 음성 메시지를 계속 이용할 수 있어요."*
- **채팅 관리 패널**: [프로필 보기] · [신고하기](기능 제한 없음, 운영팀 검토) · [차단하기](**방 자동 종료** + 상호 차단: 프로필·포스트·대화 신청 막힘, 친구 목록에서 삭제) ·
  [친구 신청](안내 팝업) · [대화방 나가기](안내 팝업 + **방 삭제**)
- 5-1: 같은 채팅창에서 상대가 친구 신청하면 **[받은 친구 신청] 팝업을 채팅창 위에 바로** 띄운다

## 이미 정해진 것 (되돌리지 말 것)

- **대화방 수명 30일** — 무대화 30일이면 `ENDED`(친구 방도 예외 없음). 무료 번역 자리는 평생
- 소켓 화면이라 공통 갱신 방침("낡았으면 1분마다 다시 읽기")의 **예외**다
- 🚨 실기기 소켓은 `adb reverse tcp:8080 tcp:8080` + `--dart-define=API_BASE_URL=http://localhost:8080`(에뮬 `10.0.2.2`는 30~60초마다 끊긴다)
- 음성 바이트는 **소켓을 지나지 않는다**(업로드 URL → 키만 메시지로, `01` "음성 메시지")
- 🆕 **채팅창은 밝은 바탕**(`Scene_Chat`, 2026-10-25) — 앱의 다른 화면과 달리. 상태바 글자를 어둡게 바꾼다
- **GIF는 되살린다, 키는 나중에**(사용자 2026-10-25) — 지금은 [GIF]를 누르면 `chatGifNotReady`. 키가 오면 검색 시트 + 메시지 종류 `GIF`(서버 `chat_messages.type` + 허용 도메인 검사) + GIF 말풍선
- **이모지는 폰 키보드 것**(기획서 5장) — 앱 자체 이모지 시트는 지웠다. 매칭 안내 줄·읽음 ✓✓도 새 시안에 없어 뺐다
- [대화방 나가기]는 **확인 팝업**을 거친다(기획서 "안내 팝업")
- 말풍선은 그림 **9조각** — `DecorationImage(centerSlice:)` 말고 `drawImageNine`(함정 #90·#94)

## 알아둘 것

- 🚧 **그림이 안 온 자리 셋**(08 §0-5): 안내 문구 `작은 배려, 아름다운 대화`(지금 폰트) · 노란 [정지](지금 `button_playstop`) · [⋯] 패널(지금 흰 글자 메뉴).
  `참고화면.png`의 사진(+) 버튼은 기획서에 없어 안 만들었다 — 사용자 확인 대기
- 개발 DB 데모 대화: Nari(LINE) ↔ `ゆい`(친구 방 `609b9d91…`)에 `demo-chat-1~4`
- 받은 음성 첫 재생이 조용히 실패한 적이 한 번 있다(재현 안 됨) — `voice_player.dart`가 실패를 말없이 삼킨다
- 실시간 파형은 *"구현 안 되면 이미지"* 가 허락돼 있다
- 번역 공급자는 아직 없다(막힌 것 D) — 개발 중 흐름은 `APP_TRANSLATE_PROVIDER=mock`으로 서버를 띄워 본다
