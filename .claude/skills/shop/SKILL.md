---
name: shop
description: 이 세션을 달빛톡 '유료 상점' 콘텐츠 전담으로 설정한다 — 기획서 261011 10장(프라임 멤버십·루나 상점·부스트·앨범 패스·자동 번역), D:\Plan_Chat\UI\Scene_Shop 위주. 사용자가 /shop을 입력할 때만 쓴다.
disable-model-invocation: true
---

# 👑 상점 세션

이 세션은 이제 **유료 상점**(프라임·루나) 담당이다. 이후 요청은 별말 없으면 상점 기준으로 해석한다.

**먼저 `.claude/content-sessions.md`를 읽고 그 §2 시작 절차를 따른다** — 특히 §4 동시 작업 규칙.
(가능하면 세션 제목을 `👑 상점`으로 바꿔 둔다.)

명령 뒤에 덧붙인 말이 있으면 그것이 첫 작업이다: $ARGUMENTS

## 담당 범위

| | 어디 |
|---|---|
| 기획서 | 261011 **10장 유료 상점** — 10-1 프라임 멤버십 · 10-2 루나 상점(10-2-1 포스트 부스트 · 10-2-2 포스트 앨범 패스 · 10-2-3 자동 번역). ⚠️ **완전 최신이 아닐 수 있다**(사용자 2026-10-25) — 대화 중 결정이 더 우선 |
| UI | **`D:\Plan_Chat\UI\Scene_Shop\`** — `PrimeSub/`(`SubStart` 구독 화면 · `SubManage` 관리 · `SubEnd` 해지 팝업 · `SubEndCancel` 해지 상태), 각 `Example/*좌표값.png`. 🚧 **`LunaShop/` · `LunaCharge/`는 2026-10-25 현재 비어 있다** — 루나 쪽은 그림이 오기 전까지 기획서·지금 화면으로 본다 |
| 에셋 | 아직 없음 → `assets/images/scene_shop/…`(전달 폴더 구조대로, 공백·대문자 정리) + **`pubspec.yaml`에 줄(폴더마다) + 완전 재빌드**. 🚨 전달 이름의 **`_kr`/`_jp`는 언어 변형** → 접미사를 떼고 `_kr`은 제자리, `_jp`는 `ja/`로(08 §0-3과 같은 규칙) |
| 클라 | `lib/features/store/` — `prime_screen.dart` · `luna_store_screen.dart` · `luna_charge_screen.dart` · `boost_screen.dart` · `pass_screen.dart` · `store_widgets.dart` · `store_provider.dart`. (`lib/features/luna/`는 빈 자리 `.gitkeep`뿐) |
| 서버 | `server/.../store/`(`StoreService` · `PurchaseService` · `EntitlementService` · 영수증 검증 `verifier/` Apple·Google·Mock · 웹훅) · `server/.../luna/`(`LunaService`) |
| 문서 | `01` §1.8 유료 상점·구독·부스트 · `02` `subscriptions`·`user_entitlements`·`luna_wallets`·`luna_transactions`·`boost_inventory`·`boost_activations`·`store_purchases` · `08` §3 BM 화면 |

**들어오는 문(다른 세션 화면에 있다 — 문을 옮기거나 바꾸면 보고에 적을 것)**:
- 상단 **[Prime]·[루나]** 버튼 — 공용 `shared/widgets/art_top_bar.dart`, 그림은 `Scene_Garden`(모든 탭)
- 포스트 화면 **[부스트]·[포스트 앨범]** 버튼 — `/post`
- **[번역 패스]** 버튼(포스트 댓글 · 채팅창 · 달빛 한마디 상세) → 자동 번역 구매 — 공용 `shared/widgets/translate_pass_button.dart`

## 기획서 10장 요지 (본문이 정본)

- **프라임**: 1개월 · 6개월(20% 할인). **중복 결제 불가**, 만료 시 같은 상품으로 **자동 갱신**. 구독 중 [Prime] → **관리 화면**.
  [자동 갱신 해지]는 언제든 — 단 **해지는 기간 끝에 적용**
- 프라임 혜택: 앨범 패스 30일 · 부스트(1시간) **10매** · 대화 신청 무제한 · 대화 신청 시 상대 받은 목록 **1일간 최상단**(다른 프라임끼리는 신청 시각순) ·
  자동 번역 무제한 30일 · 광고 제거 30일. 부스트만 **매수 충전형**, 나머지는 **구독 즉시 적용**
- **루나 상점**: 루나를 먼저 충전 → 개별 상품 구매. 상품 = 포스트 부스트(1시간 단위 매수) · 앨범 패스(7일·30일) · 자동 번역(7일·30일)
- 부스트 화면 세 상태: 보유 0 → **구매** / 보유 있고 미사용 → **사용** / 사용 중 → **사용 정보**
- 앨범 패스 · 자동 번역: 구매 전 → **구매** 화면, 구매 후 → **관리** 화면. **중복 구매 불가**, 사는 즉시 적용

## 이미 정해진 것 · 알아둘 것

- 🚧 **막힌 것 E — 실제 결제창이 없다.** 스토어 계정이 없어 영수증 **검증**(`/store/purchases:verify`)만 붙어 있다(01 §1.8 ①).
  개발 중 구매는 local 프로필의 **목 결제**(`mock-purchase-enabled`, 운영 금지)로 본다
- 부스트 **최우선권**(V23) — 기획 A 답변으로 구현돼 있다(09 §2-1)
- 기획 확인 대기: **프라임 구독 중에도 요금제 목록을 보여 줄지**(시안 img26 우측은 보여 준다) — 이번 `SubManage` 시안으로 답이 나왔는지 먼저 볼 것
- 혜택이 걸린 기능의 **판정은 각 콘텐츠 서버 코드에 흩어져 있다**(열람 제한 `GardenService.canViewAllPhotos` · 번역 무제한 · 음성 무료 횟수 등) —
  혜택을 바꾸면 그 판정을 가진 세션에 알릴 것
- 광고 제거는 **광고 자체가 아직 없다**
