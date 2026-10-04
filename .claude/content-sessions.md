# 콘텐츠 세션 공통 규칙

> `/post` · `/garden` · `/talk` · `/friend` · `/profile` 이 이 파일을 먼저 읽게 한다.
> 정본은 이 파일 하나다 — 다섯 스킬에 같은 말을 따로 적지 않는다(한쪽만 늙는다).

## 1. 세션은 여섯이다

달빛톡 작업을 **콘텐츠별 세션**으로 나눠 동시에 돌린다(2026-10-04 결정).

| 명령 | 콘텐츠 | 기획서 260919 | 주로 볼 UI (`D:\Plan_Chat\UI\`) |
|---|---|---|---|
| `/post` | 포스트 | **3장** 포스트 등록 | `Scene_Post` |
| `/garden` | 달빛가든 | **4장**(피드·댓글·대화 신청) + **8장** 달빛 한마디 | `Scene_Garden` |
| `/talk` | 대화방 | **6장** 대화방 + **5장** 채팅창 | `Scene_Talk` |
| `/friend` | 친구 | **7장** 친구관리 + **5-1** 친구 신청 | `Scene_Friend` |
| `/profile` | 프로필 | **7장** 프로필(⚠️ 기획서에 `7.`이 두 번 나온다 — 두 번째 것) | `Scene_Profile` |
| (명령 없음) | **그 외** | 1·2장 로그인·온보딩 · **9장** 유료 상점 · 공용 위젯 · 하단 주메뉴 · 문서 정리 · 환경 | — |

**"주로 볼 UI"는 출발점이지 울타리가 아니다.** 화면은 다른 콘텐츠의 그림을 빌려 쓴다:

- **하단 주메뉴 그림은 전부 `Scene_Garden`에 있다**(`menu_*`, `main_menu_icon_friend_*`) — 모든 탭 화면이 쓴다
- **상단 `Prime`·`루나` 버튼**(`button_prime`·`button_luna`)도 `Scene_Garden`에 있다 — 공용 `ArtTopBar`
- **친구 `[받은 신청]` 탭은 `Scene_Talk`의 그림을 쓴다**(바이트까지 같아 한 벌만 들였다)
- 국기·`ON` 같은 작은 그림은 콘텐츠마다 비슷한 것이 따로 오기도 한다 — 이름이 같아도 **규격을 확인**할 것
- 각 폴더의 `Example/`은 **시안**이다(실제 리소스가 아니다)

## 2. 시작할 때 (명령을 받으면 이 순서로)

1. `git pull --ff-only origin main` — 다른 기기 커밋이 있으면 [두 기기 절차](../docs/07-work-log.md)대로(서버 기동 → 마이그레이션 적용, `gen-l10n`)
2. [`docs/07`](../docs/07-work-log.md) §1(현재 상태) → [`docs/09`](../docs/09-next-task-handoff.md) **머리 + §0 표의 내 줄**
3. **UI를 건드릴 거면** [`docs/14`](../docs/14-ui-ground-rules.md) UI 대전제를 먼저 — 언어는 한·일 둘, 글자가 박힌 그림은 그림째 바뀐다, **아이콘·버튼도 그림이다**(`Icons.*`는 자리 표시)
4. 내 UI 폴더를 실제로 열어 본다. 새 전달본인지는
   `python tools/spec/compare_ui_delivery.py "D:/Plan_Chat/UI"` 로 — 결과 중 **내 `Scene_*` 줄**을 본다
5. 사용자에게 **세 줄 이내로** 보고: 지금 상태 · 내 콘텐츠의 다음 할 일(09 §0) · 전달본 변화 유무

## 3. 기획 자료 — 신뢰 순서

**(대화 중 사용자 결정) > `YYYY-MM-DD 기획사항.txt` > 기획서 `.docx` > 이미지**

- 기획서 정본: `D:\Plan_Chat\기획서\`에서 **가장 최근 `.docx`**(지금 `달빛톡 기획서_260919.docx`).
  본문은 `python tools/spec/diff_docx_text.py "<기획서>" --dump out.txt`로 뽑아 **내 장만** 읽으면 된다.
- ⚠️ `2026-09-19 기획사항.txt`는 지금 그 폴더에 **없다** — 내용은 `docs/07` §4 **2026-09-19(6)** 에 옮겨 적혀 있다.
- 🚨 기획서는 **파일명이 같아도 내용이 바뀐다**. 새로 받으면 옛 판과 통째로 diff할 것(화면만 보면 문장을 놓친다).

## 4. 🚨 동시 작업 규칙 — 여섯 세션이 한 저장소를 쓴다

1. **내 콘텐츠 파일만 고친다.** 아래 **공용 파일**을 고쳐야 하면 최소한으로 하고, 끝에 보고할 때
   *"공용 파일 ○○를 고쳤다 — △△ 화면도 함께 바뀐다"* 를 꼭 적는다.

   | 공용 파일 | 누가 같이 쓰나 |
   |---|---|
   | `lib/shared/widgets/*`(`design_canvas.dart`·`art_top_bar.dart`·`main_bottom_nav.dart` 등), `lib/core/*` | 전부 |
   | `lib/features/chat/presentation/widgets/talk_cell.dart`·`request_popup.dart` | **대화방·친구**(셀 · 팝업 세 개가 한 벌) |
   | `lib/features/chat/presentation/widgets/chat_request_dialog.dart` | 대화방·가든(4-3 대화 신청) |
   | `lib/features/postinfo/*`(`profile_view_screen.dart`·`post_info_provider.dart`) | 가든·대화방·친구·프로필 |
   | `lib/shared/widgets/request_message_input.dart`(신청 한마디 100자) | 대화방·친구 |
   | `pubspec.yaml` · `lib/l10n/*.arb`(+생성물) · `server/.../common/*` · `application.yml` | 전부 |

2. **커밋은 경로를 집어서 내 파일만.** `git add <파일들>` → `git commit`.
   🚫 `git add -A` · `git add .` · `git commit -a` · `git stash` · `git checkout -- .` · `git reset --hard` 금지 —
   같은 폴더의 **다른 세션이 쓰다 만 변경을 쓸어 담거나 지운다.**
   `git status`에 내가 만들지 않은 변경이 보이면 **손대지 않는다**(다른 세션 것이다).
3. **Flyway 번호는 경쟁이다.** 새 마이그레이션을 만들기 **직전에**
   `ls server/src/main/resources/db/migration | sort -V | tail -3`으로 최신 번호를 보고, 만들면 **바로 커밋**한다.
   같은 번호가 둘이면 서버가 아예 안 뜨고 **여섯 세션이 다 멈춘다.** 문서의 함정 번호(`docs/07` §3 `#NN`)도 같다.
4. **ARB 키는 그 화면의 기존 접두어를 따른다** — 포스트 `home*` · 가든 `garden*` · 대화방 `chat*` ·
   친구 `friend*` · 프로필 `profile*`/`interest*`. **ko·ja 둘 다** 넣고 `flutter gen-l10n` 생성물도 함께 커밋.
5. **서버(8080)와 폰은 하나다.** 서버를 다시 띄우면 다른 세션의 검증이 끊긴다 — 서버 코드나 마이그레이션을
   바꿨을 때만 재기동하고, 했다고 보고한다. `flutter analyze` 오류가 **남의 파일**에서 나면 고치지 말고 알린다
   (다른 세션이 쓰는 중일 수 있다).
6. **문서도 나눠 쓴다.**
   - `docs/07` §4 세션 로그 제목 앞에 태그: `### 2026-10-04 [포스트] — …`
   - `docs/09`는 **§0 표의 내 줄만** 고친다. 머리·나머지는 "그 외" 세션 몫이다.
   - 내 콘텐츠의 API·스키마·리소스가 바뀌면 `01`·`02`·`08`의 **해당 절만** 고친다.
7. **범위 밖 요청도 사용자가 시키면 한다.** 다만 *"그건 ○○ 세션 범위라 거기서 동시에 만지고 있을 수 있다"* 를 한 줄 알린다.
8. 푸시 전에 `git pull --ff-only origin main`. 안 되면(다른 기기와 갈라짐) **멈추고 사용자에게 알린다** —
   남의 변경이 섞인 작업 폴더에서 rebase·merge를 혼자 하지 않는다.

## 5. 모든 콘텐츠에 걸린 결정 (되돌리지 말 것)

- 고정 화면은 **스크롤하지 않는다** — 넘치면 늘어나는 칸 하나가 흡수(`Expanded`). 끌어서 울렁이면 안 된다
- **막힌 버튼은 죽이지 말고 이유를 말한다** — 서버 `ErrorCode` 이름을 그대로 문구 키로
- 클라 갱신은 "**낡았으면 다시 읽기**"(1분). 소켓 화면은 예외
- 빈 목록이 생기는 피드는 **빈 상태 화면을 만들지 않는다** — 🤖 봇 데이터가 채울 예정(09 §4-1)
- 디자인 캔버스 **1080×2640**, `DesignCanvas.scaleOf(context)`, 일본어 그림은 같은 이름으로 `ja/`에 + `DesignCanvas.localizedAssets`
