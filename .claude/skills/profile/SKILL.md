---
name: profile
description: 이 세션을 달빛톡 '프로필' 콘텐츠 전담으로 설정한다 — 기획서 7장 프로필(사진·관심사·소개·지역), D:\Plan_Chat\UI\Scene_Profile 위주. 사용자가 /profile을 입력할 때만 쓴다.
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
| 기획서 | **7장 프로필** — ⚠️ 기획서에 `7.`이 두 번 있다(친구관리 다음의 두 번째 `7. 프로필`). 사진 1장 · 관심사 · 소개 · 지역 · Prime 진입 |
| UI | **`D:\Plan_Chat\UI\Scene_Profile\`** — 🚨 **2026-10-04 현재 비어 있다.** 리소스가 오기 전까지는 기획서 그림과 다른 Scene의 공용 그림(하단 주메뉴·Prime·루나 = `Scene_Garden`)으로 본다 |
| 에셋 | 아직 `assets/images/scene_profile/` 없음 — 오면 폴더를 만들고 **`pubspec.yaml`에 줄을 넣고 완전 재빌드**(폴더 선언은 재귀가 아니다) |
| 클라 | `lib/features/profile/` — `profile_screen.dart` · 시트 `interests_edit_sheet.dart`·`regions_edit_sheet.dart` · `intro_edit_dialog.dart` · 목록·한도 `profile_catalog.dart` |
| 서버 | `server/.../profile/` |
| 공용 | 상대 프로필 보기 `postinfo/presentation/screens/profile_view_screen.dart`(대화방·친구가 부른다) · 사진 시트 `shared/widgets/photo_source_sheet.dart` |
| 문서 | `01` profile API · `02` `user_profiles`·관심사·지역 · **`08` §0-2(관심사 그림)** · `13` |
| 인접 | Prime [자세히 보기] → 상점(`store/`, "그 외" 몫) · 가입 때 프로필 생성(2-1, `onboarding/`, "그 외" 몫) |

## 이미 정해진 것 (되돌리지 말 것)

- **관심사는 최대 3개**(종류는 37종) — `ProfileCatalog.maxInterests = 3`. 한때 "8개 유지"로 잘못 옮겨 적었다가 고쳤다
- 🚨 **관심사의 버튼·아이콘은 전부 이미지 파일이다** — 코드가 그리거나 글자로 하는 게 아니다(기획 2026-09-19).
  `profile_catalog.dart`의 `IconData`는 **자리 표시**다. 관심사 그림은 74장 넘게 필요하고 지금은 `영화` 한 장뿐(08 §0-2)
- 지역은 최대 2개, 소개 한마디 최대 50자, 프로필 사진 1장(앨범·카메라·제거)
- 한도를 넘기면 버튼을 죽이지 말고 **기획서 문구로 안내 팝업**("관심사 등록은 3개 까지만 선택할 수 있습니다" 등)

## 알아둘 것

- 기획 확인 대기: 프라임 구독 중에도 요금제 목록을 보여 줄지(시안 img26 우측은 보여 준다) — 상점과 걸쳐 있다
- 상대 프로필 보기([프로필 보기])에는 **신고·차단 메뉴가 없다** — 대화방 세션의 미결 질문과 이어진다(`10` §0-2)
