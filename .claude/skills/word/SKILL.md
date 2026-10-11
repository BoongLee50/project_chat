---
name: word
description: 이 세션을 달빛톡 '달빛 한마디' 콘텐츠 전담으로 설정한다 — 기획서 261002 9장 달빛 한마디 이벤트(타이틀·목록·상세 댓글·내 한마디). 사용자가 /word를 입력할 때만 쓴다.
disable-model-invocation: true
---

# 🏮 달빛 한마디 세션

이 세션은 이제 **달빛 한마디** 담당이다. 이후 요청은 별말 없으면 달빛 한마디 기준으로 해석한다.

**먼저 `.claude/content-sessions.md`를 읽고 그 §2 시작 절차를 따른다** — 특히 §4 동시 작업 규칙.
(가능하면 세션 제목을 `🏮 달빛 한마디`로 바꿔 둔다.)

명령 뒤에 덧붙인 말이 있으면 그것이 첫 작업이다: $ARGUMENTS

## 담당 범위

| | 어디 |
|---|---|
| 기획서 | 261002 **9장 달빛 한마디 이벤트** — 9-1 목록 · *"8-2"* 상세 호출·댓글 · *"8-3"* 내 한마디 작성·상세. ⚠️ 뒤 둘은 **번호가 8로 잘못 붙어 있다**(실제 9-2·9-3). 유료 상점도 `9.`로 겹친다. 260919까지는 **8장**이었다 |
| UI | 🚨 **2026-10-11 현재 전용 폴더가 없다**(`Scene_Word` 같은 것이 아직 안 옴) — 화면은 코드로 그려 둔 상태다. 기획서 그림(13 문서의 img23~25)으로 본다. 리소스가 오면 그 폴더가 주 UI가 된다 |
| 입구 | `[달빛 한마디]` 버튼 그림 `button_Moonlight`은 **`Scene_Garden`에 있고 가든 세션 몫**(가든 필터 줄 네 번째 칸, `garden_screen.dart`가 `DailyIntroScreen.route()`를 연다) |
| 에셋 | 아직 없음 — 오면 `assets/images/scene_word/`(가칭)를 만들고 **`pubspec.yaml`에 줄 + 완전 재빌드**(폴더 선언은 재귀가 아니다) |
| 클라 | `lib/features/daily/` — 타이틀 `daily_intro_screen.dart` · 목록 `daily_list_screen.dart` · 상세 `daily_detail_screen.dart` · 작성 `daily_write_screen.dart` · `daily_provider.dart` · `daily_api.dart` |
| 서버 | `server/.../dailyquestion/` · `db/migration` **V14**(`daily_questions` · `daily_question_bank` · `daily_answers` · `daily_answer_likes` · `comments.target_type='DAILY_ANSWER'`) · 정리 배치 `daily-cleanup-cron`(18:05) |
| 문서 | `01` §1.9 달빛 한마디 API · `02` daily 표 · `13` 달빛 한마디(img23~25) · `08` #6(입구 버튼 일본어판) |

🚨 **가든과 같이 쓰는 것** — 고치면 가든도 바뀐다(보고에 적을 것):
- **댓글 창** `lib/features/garden/presentation/widgets/comments_sheet.dart` — 가든 4-2 [포스트 댓글]과 한 벌이다. 가든 세션이 시안대로 개편했다(2026-10-04)
- 서버 `comment/`(`CommentTarget.DAILY_ANSWER`) — 댓글 3단계·50자·이미지 1장 규칙이 포스트 댓글과 같은 코드다
- 사진 크게 보기 `shared/widgets/image_viewer.dart` · 번역 패스 화면은 상점(`store/`, "그 외" 몫)

## 기획서 9장 요지 (본문이 정본 — 바뀌었으면 본문을 따른다)

- **KST 18시에 모든 정보 초기화 + 새 질문**. 타이틀 화면에 댓글·좋아요 누른 사람 수, 남은 시간
- [참여하기] → 목록. **기본 [최신순]**, [인기순] = **좋아요 + 댓글 수의 합**
- 내 한마디가 없는데 [내 한마디]를 누르면 하단 안내: *"아직 작성한 내 한마디가 없어요. 오늘의 질문에 답해 보세요."*
- 한마디 **최대 100자**(넘으면 *"100자까지 입력할 수 있어요"*), 메인 이미지 **선택·최대 1장**
- 상세: 좋아요 +1, 댓글 **3단계**까지, 댓글 **50자**·이미지 1장, 첨부 이미지는 원본만 팝업
- 번역: **댓글창 5회 호출까지 무료** → 다 쓰면 *"무료 번역을 모두 사용했어요…"* 안내. Prime·자동번역 패스는 무제한

## 알아둘 것

- 🚨 **한마디 100자를 세는 단위가 프로젝트 규칙과 다르다** — 서버는 `body.length()`(UTF-16), 앱은 Flutter `maxLength`(글자 묶음)다.
  신청 한마디는 **코드포인트로 통일**했다(함정 #82, `shared/widgets/request_message_input.dart`) — 이모지가 섞이면 앱은 통과시키고 서버는 거절할 수 있다. 손볼 때 같이 맞출 것
- 기획 확인 대기: 댓글창 무료 5회의 **초기화 주기** — 지금은 영업일마다 초기화로 읽었다. 평생 5회면 `lifetime_usage`로(09 §2-1)
- 빈 목록일 때 빈 상태 화면을 만들지 않는 원칙(🤖 봇 데이터가 채운다)이 여기에도 걸리는지는 정해진 적 없다 — 만들기 전에 사용자에게 물을 것
- 18:05 배치가 지난 영업일 것을 지운다 → 18시 전후로 확인하면 목록이 비는 것은 정상
