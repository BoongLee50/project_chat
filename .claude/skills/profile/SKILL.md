---
name: profile
description: 이 세션을 달빛톡 '프로필' 콘텐츠 전담으로 설정한다 — 기획서 8장 프로필([작성하기]·[미리 보기]) + 타이틀(로그인) 화면 + 온보딩(가입 정보 입력), D:\Plan_Chat\그래픽 소스\프로필 화면 위주. 사용자가 /profile을 입력할 때만 쓴다.
disable-model-invocation: true
---

# 🙂 프로필 세션

이 세션은 이제 **프로필** 담당이다 — 🆕 **타이틀(로그인) 화면과 온보딩(가입 정보 입력)도 여기서 진행한다**(사용자 2026-11-21, "그 외"에서 옮겨 옴) — 앱을 켜서 프로필이 만들어지기까지가 한 세션이다. 이후 요청은 별말 없으면 프로필 기준으로 해석한다.

**먼저 `.claude/content-sessions.md`를 읽고 그 §2 시작 절차를 따른다** — 특히 §4 동시 작업 규칙.
(가능하면 세션 제목을 `🙂 프로필`로 바꿔 둔다.)

명령 뒤에 덧붙인 말이 있으면 그것이 첫 작업이다: $ARGUMENTS

## 담당 범위

| | 어디 |
|---|---|
| 기획서 | **8장 프로필 · 8-1 작성하기**(261002판부터 번호가 바로잡혔다 — 260919까지는 두 번째 `7.`) |
| UI | **`D:\Plan_Chat\UI\Scene_Profile\`** `Create/`(작성하기) · `Preview/`(미리 보기) — 좌표는 각 `Example/`의 `*좌표.png` · 🚨 **2026-11-15부터 그래픽은 `D:\Plan_Chat\그래픽 소스\프로필 화면\`**(옛 `UI\Scene_Profile`와 같은 것, 폴더 이름만 한글). **시안은 `Example/` 없이 섞여 온다 — 파일명이 한글이고 완성된 화면이면 참고 화면이지 리소스가 아니다.** 옛 이름 대조표는 `.claude/content-sessions.md` §1 |
| 에셋 | `assets/images/scene_profile/{create,preview}/` + `create/ja/` — 새 폴더면 **`pubspec.yaml`에 줄을 넣고 완전 재빌드**(폴더 선언은 재귀가 아니다). 전달 이름의 `_kr`/`_jp`는 떼고 넣는다(08 §0-3) |
| 클라 | `lib/features/profile/` — `profile_screen.dart`([작성하기]) · `profile_preview_screen.dart` · 위젯 `profile_preview_view.dart`(**남도 보는 창**) · `profile_tag_chip.dart` · `profile_notice_dialog.dart` · 시트 `interests_edit_sheet.dart`·`regions_edit_sheet.dart` · 목록·한도·칩 그림 `profile_catalog.dart` |
| 서버 | `server/.../profile/` (V28) |
| 공용 | 상대 프로필 보기 `postinfo/presentation/screens/profile_view_screen.dart`(대화방·친구·가든이 부른다 — 그림은 `ProfilePreviewView`) · 사진 시트 `shared/widgets/photo_source_sheet.dart` |
| 문서 | `01` profile API · `02` `user_profiles`·관심사·지역 · **`08` §0-2(관심사)·§0-3(프로필 그림)** · `10` §0-3 · `13` |
| 검증 | `python tools/verify/verify_profile.py` (local 서버) |
| 🆕 타이틀 화면 | **로그인 화면 = 앱을 처음 켜면 나오는 타이틀 화면**(2026-11-21 이 세션으로) — 기획서 **2장 로그인**. 클라 `lib/features/auth/presentation/screens/login_screen.dart` · 공급자 토큰 단계 `lib/features/auth/data/social/social_sign_in.dart` · 서버 `server/.../auth/`(`social/` 검증기 넷) · 배경 `assets/images/login_bg.jpg`. 아래 **"타이틀 화면"** 절을 볼 것 |
| 🆕 온보딩 | **가입 정보 입력 = 타이틀 다음 화면들**(2026-11-21 이 세션으로) — 기획서 **2-1 프로필 생성 · 2-2 회원 생성 프로세스**. 닉네임(10자 · 특수문자·이모지 금지 · 중복 · 금지어 → [MSG NUM2]) → 출생년도(만 18세 미만 → [MSG NUM3]) → 성별·국가. 클라 `lib/features/onboarding/`(`nickname_screen` · `birth_year_screen` · `gender_country_screen` · `onboarding_scaffold` · `onboarding_provider`) · 서버 `GET /profile/nickname:check` · `POST /profile`(`server/.../profile/` — 닉네임 검사 `NicknameValidator`, 테스트 있음) · 로그인 응답 `status`(NEW · PROFILE_REQUIRED → 온보딩으로) · 배경 `onboarding_1~3.jpg` · 문서 `01` §1.2 |
| 인접 | Prime·루나는 이제 프로필에 없다(상단 버튼·포스트 화면이 연다) |

## 타이틀 화면 (2026-11-21 이 세션으로)

**지금 상태**("그 외" 세션이 2026-11-15에 소셜 로그인 1단계까지 해 두었다 — 07 §4 그날 · 09 §2-2 F):
- 버튼 넷 **라인 · 카카오 · 구글 · 애플**(애플 추가 V32). 애플은 **아이폰에서만**, 개발(목) 빌드는 어디서나 — 안드로이드에도 둘지 **사용자 결정 대기**
- 로그인 = ① 공급자 토큰(`SocialSignIn`: 개발 빌드 `MockSocialSignIn` · 릴리스 `SdkSocialSignIn`) → ② `POST /auth/social`
- 서버 검증기: 애플 JWKS 서명 · 카카오 `app_id` 대조 · 구글 클라이언트 ID 여럿 · 실패는 401(테스트 `SocialAuthProvidersTest` 13건)
- 🚧 **2단계**(키를 받으면): `SdkSocialSignIn`에 SDK 넷 연결 — 패키지·필요한 값은 그 파일 주석. 지금은 *"아직 준비 중"* 안내
- 🚧 **3단계**: Mac에서 iOS·애플 로그인

**기다리는 것**(사용자 몫 — 09 §2-2 F 목록): 최종 앱 ID · 네 곳 개발자 콘솔 키 · Mac · 기획서 2장에 애플 추가(261111은 아직 *"LINE, KAKAO, GOOGLE"*) ·
🎨 **타이틀 화면 그림**(버튼 4 · 배경, 한·일 — 지금 버튼은 **코드로 그린 자리 표시**, 배경 `login_bg.jpg`에는 폐지된 *"밤에만 만나는 대화"* 가 박혀 있다 = 막힌 것 C) ·
**앱 안 계정 삭제**(애플 심사 필수, 지금 없다).

⚠️ 타이틀 화면은 **고정 화면**이다 — 스크롤하지 않는다(공통 규칙 §5). 버튼이 넷이 되며 짧은 폰에서 넘치지 않는지 볼 것.
⚠️ 서버 `auth/`를 고치면 **모든 화면의 로그인**이 걸린다 — 마이그레이션·재기동은 공통 규칙 §4대로.

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
- ✅ **기획서와 어긋나던 다섯 자리는 사용자가 확정했다(2026-11-15, `10` §0-3)** — 기획서 문구가 옛것이어도 이쪽이 맞다:
  자기소개 팝업은 **300자**(기획서 "50자"는 옛 문구) · 지역 팝업은 **1군데**(기획서 "2군데"는 옛 문구, 바꿔 끼우기 말고 팝업 그대로) ·
  사진 25%는 **얼굴·자유 두 칸 다** 올려야 · 자유 사진 없는 큰 칸은 **회색 + 사람 모양 아이콘 임시** · 로그아웃은 **[작성하기] 머리 오른쪽 위 `⋯` 그대로**
- [프로필 보기] 하단 버튼은 **그림**(`preview/button_talk` 대화하기 · `button_friend` 친구 신청, 2026-11-15)

## 알아둘 것

- 기획 확인 대기: 프라임 구독 중에도 요금제 목록을 보여 줄지(시안 img26 우측은 보여 준다) — 상점과 걸쳐 있다
- 상대 프로필 보기([프로필 보기])에는 **신고·차단 메뉴가 없다** — 대화방 세션의 미결 질문과 이어진다(`10` §0-2)
- 남이 보는 [프로필 보기] 하단 버튼은 **`profileViewActionOf()`** 가 정한다 — 나·친구·나에게 대화 신청한 사람은 없음, 대화 중이면 [친구 신청], 아무 관계 아니면 [대화 신청](2026-10-05)
- 남이 보는 [프로필 보기]에는 `[원문보기]`(나라 다르면 눌림 · 같으면 흐리게) — 번역 기능 전이라 자리만. 내 미리 보기엔 없다
- [작성하기]는 **머리 고정**(진행도 아래부터 스크롤) · 자유 사진이 없으면 미리 보기 큰 칸은 **빈 칸**(얼굴로 채우지 않는다)
