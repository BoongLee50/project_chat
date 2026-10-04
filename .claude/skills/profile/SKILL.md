---
name: profile
description: 이 세션을 달빛톡 '프로필' 콘텐츠 전담으로 설정한다 — 기획서 8장 프로필([작성하기]·[미리 보기]), D:\Plan_Chat\UI\Scene_Profile 위주. 사용자가 /profile을 입력할 때만 쓴다.
disable-model-invocation: true
---

# 🙂 프로필 세션

이 세션은 이제 **프로필** 담당이다. 이후 요청은 별말 없으면 프로필 기준으로 해석한다.

**먼저 `.claude/content-sessions.md`를 읽고 그 §2 시작 절차를 따른다** — 특히 §4 동시 작업 규칙.
(가능하면 세션 제목을 `🙂 프로필`로 바꿔 둔다.)

명령 뒤에 덧붙인 말이 있으면 그것이 첫 작업이다: $ARGUMENTS

## 담당 범위

| | 어디 |
|---|---|
| 기획서 | **8장 프로필 · 8-1 작성하기**(261002판부터 번호가 바로잡혔다 — 260919까지는 두 번째 `7.`) |
| UI | **`D:\Plan_Chat\UI\Scene_Profile\`** `Create/`(작성하기) · `Preview/`(미리 보기) — 좌표는 각 `Example/`의 `*좌표.png` |
| 에셋 | `assets/images/scene_profile/{create,preview}/` + `create/ja/` — 새 폴더면 **`pubspec.yaml`에 줄을 넣고 완전 재빌드**(폴더 선언은 재귀가 아니다). 전달 이름의 `_kr`/`_jp`는 떼고 넣는다(08 §0-3) |
| 클라 | `lib/features/profile/` — `profile_screen.dart`([작성하기]) · `profile_preview_screen.dart` · 위젯 `profile_preview_view.dart`(**남도 보는 창**) · `profile_tag_chip.dart` · `profile_notice_dialog.dart` · 시트 `interests_edit_sheet.dart`·`regions_edit_sheet.dart` · 목록·한도·칩 그림 `profile_catalog.dart` |
| 서버 | `server/.../profile/` (V28) |
| 공용 | 상대 프로필 보기 `postinfo/presentation/screens/profile_view_screen.dart`(대화방·친구·가든이 부른다 — 그림은 `ProfilePreviewView`) · 사진 시트 `shared/widgets/photo_source_sheet.dart` |
| 문서 | `01` profile API · `02` `user_profiles`·관심사·지역 · **`08` §0-2(관심사)·§0-3(프로필 그림)** · `10` §0-3 · `13` |
| 검증 | `python tools/verify/verify_profile.py` (local 서버) |
| 인접 | 가입 때 프로필 생성(2-1, `onboarding/`, "그 외" 몫) · Prime·루나는 이제 프로필에 없다(상단 버튼·포스트 화면이 연다) |

## 이미 정해진 것 (되돌리지 말 것)

- **관심사는 최대 3개**(종류는 37종) — `ProfileCatalog.maxInterests = 3`. 한때 "8개 유지"로 잘못 옮겨 적었다가 고쳤다
- 🚨 **관심사의 버튼·아이콘은 전부 이미지 파일이다** — 코드가 그리거나 글자로 하는 게 아니다(기획 2026-09-19).
  `profile_catalog.dart`의 `IconData`는 **자리 표시**다. 관심사 그림은 74장 넘게 필요하고 지금은 `영화` 한 장뿐(08 §0-2)
- 🚨 **[미리 보기] 창 = 남이 내 프로필을 눌렀을 때 뜨는 창**(2026-10-04) — 두 화면이 `ProfilePreviewView` 하나를 쓴다. 갈라 놓지 말 것
- 프로필 탭의 기본은 언제나 **[작성하기]**. 네 단계(사진·자기소개·관심사·활동 지역) 하나에 25%
- 사진 **두 칸** — 얼굴(`photo_key`, 목록·셀용) · 자유(`main_photo_key`, 미리 보기 메인)
- 자기소개 **300자**(코드포인트, 띄어쓰기 포함) · 활동 지역 **1곳** · 관심사 3개
- 이번 프로필은 **두 화면 다 스크롤한다**(2026-10-04 — 고정 화면 무스크롤 원칙의 예외)
- 회색 설명 글자는 **폰트, RGB(178,178,183)** · 제목(`mark_*`)·버튼은 그림
- 한도를 넘기면 버튼을 죽이지 말고 **안내 팝업**(`showProfileNotice`)

## 알아둘 것

- 기획 확인 대기: 프라임 구독 중에도 요금제 목록을 보여 줄지(시안 img26 우측은 보여 준다) — 상점과 걸쳐 있다
- 상대 프로필 보기([프로필 보기])에는 **신고·차단 메뉴가 없다** — 대화방 세션의 미결 질문과 이어진다(`10` §0-2)
- 판단으로 채운 자리(팝업 문구의 옛 숫자 둘 · 사진 25% 조건 · 로그아웃 자리)는 `10` §0-3
- [작성하기]는 **머리 고정**(진행도 아래부터 스크롤) · 자유 사진이 없으면 미리 보기 큰 칸은 **빈 칸**(얼굴로 채우지 않는다)
