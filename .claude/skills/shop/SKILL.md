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
| 기획서 | **261111 10장 유료 상점**(261101과 충돌하면 261111) — 10-1 프라임 멤버십 · 10-2 포스트 부스트 · 10-3 포스트 앨범 · 10-4 자동 번역. **루나는 없다**(2026-11-14). ⚠️ 대화 중 결정이 더 우선 |
| UI | **`D:\Plan_Chat\UI\Scene_Shop(New)\`** — `상품별 구매 화면` · `상품별 관리 화면`(프라임 구독 관리 포함) · `상품별 구매 확인 팝업`. 🚨 **시안은 폴더 없이 섞여 온다** — 한글 이름 + 화면 전체 완성형이면 시안(content-sessions §1). 옛 `Scene_Shop`(PrimeSub·Luna*)은 대체됨 |
| 에셋 | `assets/images/scene_shop/prime_sub/…`(프라임) · `assets/images/scene_shop/item/`(상품 구매·관리·구매 완료 — 폴더마다 겹쳐 와서 한 벌) + 각 `ja/`. 새 폴더면 **`pubspec.yaml`에 줄 + 완전 재빌드**. 🚨 전달 이름의 **`_kr`/`_jp`는 언어 변형** → 접미사를 떼고 `_kr`은 제자리, `_jp`는 `ja/` |
| 클라 | `lib/features/store/` — `prime_screen.dart` · `shop_item_screen.dart`(상품 구매/관리 한 화면) · `widgets/shop_popups.dart`(구매 완료 · 프라임 구매 완료 · 부스트 사용 확인) · `widgets/store_widgets.dart`(`ShopCanvas`·`ShopPopup`·`ShopKind`) · `store_provider.dart`. `boost_screen.dart`·`pass_screen.dart`는 **문만**. |
| 서버 | `server/.../store/`(`StoreService` · `PurchaseService` · `EntitlementService` · 영수증 검증 `verifier/` Apple·Google·Mock · 웹훅) · `server/.../luna/`(`LunaService`) |
| 문서 | `01` §1.8 유료 상점·구독·부스트 · `02` `subscriptions`·`user_entitlements`·`luna_wallets`·`luna_transactions`·`boost_inventory`·`boost_activations`·`store_purchases` · `08` §3 BM 화면 |

**들어오는 문(다른 세션 화면에 있다 — 문을 옮기거나 바꾸면 보고에 적을 것)**:
- 상단 **[Prime]** 버튼 — 공용 `shared/widgets/art_top_bar.dart`, 그림은 `Scene_Garden`(모든 탭). 🗑 [루나] 버튼은 2026-11-14 없어졌다
- 포스트 화면 **[포스트 부스트]·[포스트 앨범]** 버튼 — `/post` → 갖고 있으면 관리, 없으면 구매
- **[번역 패스]** 버튼(포스트 댓글 · 채팅창 · 달빛 한마디 상세) → 자동 번역 구매 — 공용 `shared/widgets/translate_pass_button.dart`

## 기획서 10장 요지 (261111 본문이 정본)

- **루나 없음** — 프라임 멤버십(구독) + 개별 상품 셋을 **결제창으로 바로** 산다
- **프라임**: 1개월 · 6개월(20% 할인). 중복 결제 불가, 자동 갱신. 구매 → **구매 완료 팝업** → [보유 상품 확인] → 관리. [구독 관리] → 해지 팝업 → [해지 신청 취소]. 해지는 기간 끝에 적용
- 프라임 혜택: 앨범(구독 기간) · 부스트 **매달 10개** · 대화 신청 무제한(+ 받은 목록 1일 최상단) · 자동 번역 · 광고 제거
- **개별 상품**: 포스트 부스트 5·10개 · 포스트 앨범 7·30일 · 자동 번역 7·30일(30일·10개는 20% 할인). 구매 화면에서 [프라임 멤버십] 배너 → 프라임
- 보유분이 있으면 **관리** 화면 — [프라임 구독분]·[상점 구매분] 따로 · **프라임 구독분 먼저 사용** · 상점분이 다 소진돼야 다시 산다
- 부스트 [사용하기 (1개)] → 확인 팝업 → 사용 → 그 칸 `이용 중` · 버튼은 [나가기]로

## 이미 정해진 것 · 알아둘 것

- ✅ 사용자 결정(2026-11-14): 프라임 부스트는 **매달 10개로 다시 채움**(남은 건 사라짐 · 구독 끝나면 사라짐) · 상점 패스는 **프라임이 끝난 뒤부터** 흐름 · 루나는 상점·상단 버튼까지 걷어냄(서버 루나는 대화 신청이 써서 남김)
- 🚧 **막힌 것 E — 실제 결제창이 없다.** 스토어 계정이 없어 영수증 **검증**(`/store/purchases:verify`)만 붙어 있다(01 §1.8 ①).
  개발 중 구매는 local 프로필의 **목 결제**(`mock-purchase-enabled`, 운영 금지)로 본다
- 부스트 **최우선권**(V23) — 기획 A 답변으로 구현돼 있다(09 §2-1)
- ✅ 프라임 구독 중엔 요금제 목록을 안 보인다 — `SubManage` 시안이 그 자리에 구독 정보를 둔다(2026-10-25)
- 혜택이 걸린 기능의 **판정은 각 콘텐츠 서버 코드에 흩어져 있다**(열람 제한 `GardenService.canViewAllPhotos` · 번역 무제한 · 음성 무료 횟수 등) —
  혜택을 바꾸면 그 판정을 가진 세션에 알릴 것
- 광고 제거는 **광고 자체가 아직 없다**
