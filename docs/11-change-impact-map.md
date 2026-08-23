# 변경 영향 지도 (기획 변경 → 비용 산정)

> **용도**: 기획에서 "이거 바꿀 수 있어요?"가 왔을 때 **그 자리에서 비용을 답하기 위한 표**.
> 기획이 어떻게 바뀌든 쓰이므로, 기획 종속 문서([10](10-open-questions.md))와 달리 **버려지지 않는다.**
>
> ⚠️ **여기에 값(숫자)을 적지 않는다.** 값을 복제하면 코드와 금방 어긋나 오히려 해가 된다.
> 이 문서는 **"그 규칙이 어디에 있나"** 만 말한다. **값의 정본은 언제나 `application.yml`이다.**

**비용 등급**

| 등급 | 뜻 | 판단 기준 |
|---|---|---|
| 🟢 **설정** | `application.yml` 한 줄. 재배포도 불필요(값만 주고 재기동) | `@Value`로 주입돼 있는가 |
| 🟡 **코드** | 서버 로직이나 클라 화면 수정. 반나절~하루 | 로직·화면 구조가 바뀌는가 |
| 🔴 **DB** | Flyway 마이그레이션 + 기존 데이터 이전 | 스키마·키 구조가 바뀌는가 |

**현재 설정값을 보는 법** (문서를 믿지 말고 이걸 실행할 것)

```bash
sed -n '/^app:/,$p' server/src/main/resources/application.yml
```

---

## 1. 설정으로 이미 빠져 있는 것 — 🟢 즉답 가능

**여기 있는 값은 "네, 설정만 바꾸면 됩니다"로 답해도 된다.** 코드 수정도 배포도 없다.

| 영역 | 설정 키 | 무엇을 정하나 |
|---|---|---|
| 운영시간 | `app.gate.open-hour` · `close-hour` | 몇 시부터 몇 시까지 여는가 |
| 음성 메시지 | `app.chat.voice-max-duration-ms` | 최대 녹음 길이(⚠️ 클라 상수도 같이) |
| 포스트 | `app.post.max-photos-free` · `max-photos-pass` | 사진 몇 장까지 (무료/앨범패스) |
| 포스트 | `app.post.replace-limit-free` · `replace-limit-pass` | 하루 교체 몇 번 |
| 포스트 | `app.post.upload-window-minutes` | 무료 사용자의 등록 가능 창 |
| 대화 신청 | `app.chat.free-requests-per-day` · `request-luna-cost` | 하루 몇 번 공짜, 그 뒤 루나 얼마 |
| 채팅 보관 | `app.chat.retention-days` · `retention-days-friend` | 메시지 며칠 보관 (매칭/친구) |
| 친구 | `app.friend.max-count` · `max-count-premium` | 최대 몇 명 (일반/프라임) |
| 번역 | `app.translate.free-comments-per-day` · `free-chat-targets-per-day` | 무료 번역 쿼터 |
| 번역 | `app.translate.provider` | 공급자 교체(`none`=패스스루) |
| 달빛가든 | `app.garden.score-pick` · `score-online` | 피드 스코어 가중치 |
| 상점 | `app.store.luna-products` | 부스트·패스 **가격·구성 전부** |
| 상점 | `app.store.luna-packs` | 충전 패키지 구성·보너스 |
| 상점 | `app.store.prime-plans` | 프라임 기간·혜택·부스트 지급량 |
| 스케줄러 | `app.scheduler.*-cron` | 개방·종료·정리 시각 |
| 프로필 | `app.profile.forbidden-nicknames` | 금지 닉네임 |
| 인프라 | `app.storage.*` · `app.redis.enabled` · `app.jwt.*` | 저장소·Redis·토큰 수명 |

> 2026-08-09에 **BM 수치 8개를 코드 상수에서 설정으로 옮겼다**(대화 신청 2종, 포스트 4종, 무료 번역 2종
> + 등록 창·스코어 가중치). 그전에는 이것들이 `private static final`이라 값 하나 바꾸는 데도
> 코드 수정과 재배포가 필요했다.

---

## 2. 도메인별 지도

### 2-1. 운영시간 · 영업일

| 무엇 | 어디 | 비용 |
|---|---|---|
| 여는/닫는 시각 | `app.gate.*` → `GateService` | 🟢 |
| 어떤 기능이 잠기나 | `requireGateOpen()` — chat·garden·post **10곳** | 🟡 |
| 화면 안내 | `GateClosedView` · `GateBanner` + ARB 게이트 문구 | 🟡 |
| **"하루"의 경계** | `session_date` — **6개 테이블**(`posts` · `daily_usage` · `feed_skips` · `daily_translate_targets` · `boost_activations` · `post_stats`) | 🔴 |
| 06시 일괄 종료 | `SchedulerService` + `SYSTEM_CLOSE` 통지 | 🟡 |

> ⚠️ **게이트를 없애는 건 설정 한 줄이지만, 영업일 개념은 그렇지 않다.**
> 하루 종일 열리면 `session_date`를 무엇으로 끊을지(자정? 06시 유지?) 새로 정해야 한다.
> 자세한 건 [04 §4-1](04-progress-and-roadmap.md).

### 2-2. 오늘의 포스트

| 무엇 | 어디 | 비용 |
|---|---|---|
| 사진 수·교체 횟수·등록 창 | `app.post.*` | 🟢 |
| 사진 1장당 한 건 = 포스트 1건 구조 | `posts` ↔ `post_photos`(FK CASCADE) | 🔴 |
| 하루 한 마디 길이 | `OneLinerRequest`의 `@Size` | 🟡 (아래 §3 참고) |
| 등록 창 UI·남은 시간 | `home_screen.dart` + ARB | 🟡 |

### 2-3. 달빛가든

| 무엇 | 어디 | 비용 |
|---|---|---|
| 스코어 가중치 | `app.garden.score-*` | 🟢 |
| 스코어 **공식 자체** | `GardenService` 정렬 로직 | 🟡 |
| 필터 종류(성별·나이·국가·스포트라이트) | `GardenMapper` 쿼리 + 클라 필터 칩 **이미지** | 🟡 (이미지 재발주 포함) |
| 스킵 복귀·갱신 감지 | `feed_skips` · `posts.content_updated_at` (V8) | 🔴 |
| 한 페이지 카드 수 | `GardenService.PAGE_SIZE` 상수 | 🟡 ([07 §5](07-work-log.md) 부채와 얽혀 있어 일부러 안 뺐다) |
| 댓글 길이 | `CreateCommentRequest`의 `@Size` | 🟡 |

### 2-4. 채팅 · 대화 신청

| 무엇 | 어디 | 비용 |
|---|---|---|
| 무료 횟수·루나 비용 | `app.chat.*` | 🟢 |
| 보관 기간 | `app.chat.retention-days*` → `SchedulerService` | 🟢 |
| 신청 메시지 길이 | `CreateChatRequestBody`의 `@Size` | 🟡 |
| **음성 최대 길이** | `app.chat.voice-max-duration-ms` + 클라 `kVoiceMaxDuration` | 🟢 + 🟡 (**두 곳을 함께** 바꿔야 한다) |
| 음성 **무료 횟수** | **아직 없다.** 넣으면 사용량을 어디에 셀지부터 정해야 한다(계정 누적이라 `daily_usage`로는 안 된다) | 🔴 |
| 방 타입(MATCH/FRIEND) 구분 | `chat_rooms.type` (V4) | 🔴 |
| 실시간 프로토콜 | 소켓 봉투 `{op,seq,ts,data}` · `Opcodes` | 🟡 (양쪽 동시 수정) |

### 2-5. 친구

| 무엇 | 어디 | 비용 |
|---|---|---|
| 최대 인원(일반/프라임) | `app.friend.max-count*` | 🟢 |
| **과금 여부로 나누는 분기 자체** | `FriendService.requireFriendSlot()` **한 곳** | 🟡 (작다) |
| 요청 진입점 | 채팅창 메뉴 한 곳 (클라) | 🟡 |
| 수락 시 방 승격 | `ensureFriendRoom()` + `chat_rooms.type` | 🔴 가능성 |
| 관계 모델(양방향) | `friendships` (V5) | 🔴 |

> ⚠️ **친구 기획은 아직 논의 전이다.** 현재 동작 전체는 [10 §1-1](10-open-questions.md) 표에 있다.

### 2-6. 상점(BM)

| 무엇 | 어디 | 비용 |
|---|---|---|
| 가격·구성·혜택·기간 **전부** | `app.store.*` | 🟢 |
| 혜택 판정 | `EntitlementService` 한 곳으로 일원화됨 | 🟡 |
| **새로운 상품 종류** 추가 | `StoreKind` + ARB + 화면 | 🟡 |
| 영수증 검증 | `ReceiptVerifier`(현재 Mock) | 🟡 + 외부 계정 |
| 지갑·거래 이력 | `wallets` · `luna_transactions` (V6) | 🔴 |

### 2-7. 번역

| 무엇 | 어디 | 비용 |
|---|---|---|
| 무료 쿼터 | `app.translate.free-*` | 🟢 |
| 공급자 | `app.translate.provider` + `TranslationProvider` 구현체 | 🟢 + 🟡(구현체) |
| 채팅 "상대 수" 세는 방식 | `daily_translate_targets` (V7) | 🔴 |

### 2-8. 프로필 · 온보딩 · 신고

| 무엇 | 어디 | 비용 |
|---|---|---|
| 금지 닉네임 | `app.profile.forbidden-nicknames` | 🟢 |
| **최소 연령** | `ProfileService.MIN_AGE` 상수 | 🟡 (법적 기준이라 일부러 설정으로 안 뺐다) |
| 닉네임 형식(길이·문자) | `NicknameValidator` + `@Size` | 🟡 |
| 관심사·지역 목록 | `ProfileCatalog`(코드+아이콘) + ARB(문구) | 🟡 |
| 관심사 8개·지역 2곳 상한 | `InterestsRequest` · `RegionsRequest`의 `@Size` + `ProfileCatalog.max*` | 🟡 (**서버·클라 양쪽**을 같이 고쳐야 한다) |
| 신고 사유 종류 | `ReportReason` enum + ARB | 🟡 |

---

## 3. 설정으로 **못** 빼는 것 — 알고 있어야 할 한계

**Bean Validation의 `@Size(max = ...)`는 설정으로 못 뺀다.** 애노테이션 값은 컴파일 타임 상수여야 해서
`@Value`를 쓸 수 없다. 지금 이런 자리가 아래와 같다.

| 대상 | 파일 |
|---|---|
| 대화 신청 메시지 100자 | `CreateChatRequestBody` |
| 댓글 25자 · 하루 한 마디 25자 | `CreateCommentRequest` · `OneLinerRequest` |
| 소개 50자 | `IntroRequest` |
| 관심사 8개 · 지역 2곳 | `InterestsRequest` · `RegionsRequest` |
| 신고 사유·상세 500자 | `CreateReportRequest` |

→ 이 값들을 바꾸려면 **코드 수정 + 재배포**다. 자주 바뀔 것 같으면
애노테이션을 떼고 서비스에서 `@Value`로 검사하는 방식으로 옮겨야 한다(그만큼 검증이 늦게 걸린다).

⚠️ **길이 제한은 클라에도 같은 숫자가 있다**(`maxLength`, ARB 문구의 "최대 25자"). **세 곳이 함께 움직인다** —
서버 검증 · 클라 입력 제한 · 안내 문구.

---

## 4. 요청이 오면 판정하는 순서

1. **§1 표에 있나?** → 있으면 🟢 "설정만 바꾸면 됩니다"로 즉답.
2. **없으면 §2에서 도메인을 찾는다.** 🔴가 걸리면 **마이그레이션과 기존 데이터 이전**까지 답해야 한다.
3. **문구·이미지가 딸려 오는지 본다.** 이 앱은 UI 언어가 **폰트(ARB)와 이미지 둘**이다 —
   이미지 쪽이 걸리면 **디자이너 재발주 + 한·일 2세트**가 비용에 들어간다([04 §4-3](04-progress-and-roadmap.md)).

**답할 때 같이 말해야 손해가 없는 것**
- 🟢라도 **일본어 문구가 딸려 오면** 검수가 필요하다(한·일 동시 오픈 = 출시 블로커).
- 🔴는 "얼마 걸린다"보다 **"기존 사용자 데이터를 어떻게 옮기나"** 가 진짜 질문이다.
- 서버에 저장하는 건 **언제나 코드**(사유·관심사·지역·상품). 그래서 **문구가 바뀌어도 데이터는 안 흔들린다** —
  이건 강점이니 협의 때 말해도 좋다.
