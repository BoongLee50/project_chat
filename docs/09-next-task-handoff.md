# 다음 작업 인수인계 (HANDOFF)

> **이 문서는 "바로 다음에 할 작업 한 건"만 담는다.** 작업이 끝나면 내용을 통째로 다음 작업으로 갈아끼운다.
> 과거 기록은 [07 작업로그](07-work-log.md) §4로 간다.
>
> **읽는 순서**: [07](07-work-log.md) §1(현재 상태) → §2(개발 재개 절차) → **이 문서**.

- **작성**: 2026-08-02
- **마지막 커밋**: `d86e255` (`main`)
- **다음 작업**: 다국어 **②단계 — 오류 문구 다국어화**

---

## 1. 지금까지 온 길 (다국어 작업 한정)

여기부터가 "A안으로 가자"고 정한 뒤의 이야기다. 자세한 건 [07](07-work-log.md) §4의 (15)·(16) 항목.

**정한 것**
- **서버 메시지는 A안** — 서버는 **코드만** 주고 **클라가 번역**한다.
  (B안 = 서버가 `Accept-Language`로 번역해 내려주기. 번역 자원이 ARB 한곳에 모이는 A안을 택했다.)
- 언어는 **기기 설정**을 따른다. 지원하지 않는 언어(영어 등)는 **한국어로 폴백**.
- **UI 다국어와 실시간 AI 번역은 완전히 별개다.** 이 작업은 앱에 박힌 고정 문구 이야기이고,
  사용자가 쓴 글을 번역해 주는 기능은 아직 손도 안 댔다([04 로드맵](04-progress-and-roadmap.md) 별도 항목).

**①단계 = 화면 전량 ARB 이전 (완료)**
- `lib/l10n/app_ko.arb`(원문) / `app_ja.arb` 각 **378키**. 화면 6슬라이스로 나눠 커밋(`76e8f88`~`4e13156`).
- 문구를 들고 있던 모델·enum도 전부 정리 — `StoreKind`·`LunaProduct`·`ReportReason`·`ChatRequest`·
  `ProfileCatalog`·`MainBottomNav`가 이제 `L10n`을 인자로 받는다.
- `test/l10n_test.dart`로 번역 누락·placeholder·카탈로그 전 항목을 검사한다.
- 에뮬레이터 `ja-JP` 실확인 완료.

**남은 구멍이 정확히 이것** ↓

---

## 2. 다음 작업 — ②단계: 오류 문구 다국어화

### 2-1. 왜 해야 하나

지금 일본어로 앱을 켜면 **버튼·라벨은 일본어인데 오류 스낵바만 한국어**로 뜬다.
서버가 사람이 읽는 한국어 문장을 내려주고, 클라가 그걸 그대로 화면에 뿌리기 때문이다.

```
서버: throw new ApiException(ErrorCode.VALIDATION_FAILED, "이미 친구예요.")
        ↓ { "code": "VALIDATION_FAILED", "message": "이미 친구예요." }
클라: on ApiException catch (e) { return e.message; }   ← 한국어 그대로
화면: SnackBar(content: Text(error ?? l10n.friendsAccepted))
```

`code`가 이미 오고 있지만 **`VALIDATION_FAILED` 하나에 36가지 상황**이 뭉쳐 있어 분기할 수가 없다.

### 2-2. 실측 인벤토리 (2026-08-02, 직접 세어 본 값)

| 항목 | 수치 |
|---|---|
| 서버 `new ApiException(...)` 호출 | **62곳** / 11개 서비스 |
| 서로 다른 한국어 메시지 | **54개** |
| 현재 `ErrorCode` 종류 | **10개** |
| 그중 `VALIDATION_FAILED` 하나에 몰린 것 | **36곳** ← 진짜 문제 |
| `NOT_FOUND`에 몰린 것 | **15곳** |
| 클라에서 `e.message`를 그대로 반환하는 `_run` 헬퍼 | **13곳**(사실상 도메인별 7개 패턴) |
| 화면에서 `error ?? ...`로 문구를 띄우는 곳 | **22곳** |

확인 명령(그대로 붙여 쓰면 된다):

```bash
grep -rn "new ApiException(" server/src/main/java --include=*.java -A2 | grep -oP '"[^"]*[가-힣][^"]*"' | sort | uniq -c | sort -rn
```

```bash
grep -rn "return e.message" lib --include=*.dart
```

### 2-3. 설계 — 이미 정한 것 (다시 논의하지 말 것)

**① 서버는 `message`를 계속 내려보낸다.**
지우지 않는 이유는 두 가지다 — (a) 서버 로그·운영 도구에서 사람이 읽어야 하고,
(b) **클라가 아직 매핑하지 않은 코드는 `message`로 폴백**해야 점진 이전이 가능하다.
전부 한 번에 옮기지 않아도 앱이 안 깨지는 게 이 설계의 핵심이다.

**② 코드 이름은 `도메인_상황` 형태.**
`CHAT_GATE_CLOSED`, `FRIEND_ALREADY`, `POST_PHOTO_LIMIT` … 기존 10개 중 계속 쓸 것은 그대로 둔다
(`UNAUTHORIZED`·`PROVIDER_DISABLED`·`NICKNAME_INVALID`·`NICKNAME_DUPLICATE`·`LUNA_INSUFFICIENT`·
`ROOM_ALREADY_ACTIVE`·`VALIDATION_FAILED`·`NOT_FOUND`·`INTERNAL_ERROR`).
`VALIDATION_FAILED`와 `NOT_FOUND`는 **버리지 말고 최후 폴백으로 남긴다** — 새로 추가되는 예외가
코드를 안 정했을 때 떨어질 자리가 필요하다.

**③ 클라는 매핑 함수 한 곳으로 모은다.**

```dart
// lib/core/error/error_messages.dart (신설)
String errorMessage(L10n l10n, ApiException e) => switch (e.code) {
  'CHAT_GATE_CLOSED' => l10n.errorChatGateClosed,
  'FRIEND_ALREADY'   => l10n.errorFriendAlready,
  // …
  _ => e.message,   // 아직 안 옮긴 코드는 서버 문장 그대로 (폴백)
};
```

**④ 프로바이더의 반환 타입을 `Future<String?>` → `Future<ApiException?>`로 바꾼다.**
프로바이더에는 `BuildContext`가 없어 `L10n.of(context)`를 쓸 수 없다([07](07-work-log.md) 함정 #24).
전역 `L10n` 인스턴스를 두는 편법 대신, **프로바이더는 예외를 그대로 넘기고 화면이 문구로 바꾼다.**
화면은 이미 `l10n`을 갖고 있으므로 호출부는 이렇게만 바뀐다:

```dart
// 전
SnackBar(content: Text(error ?? l10n.friendsAccepted))
// 후
SnackBar(content: Text(error == null ? l10n.friendsAccepted : errorMessage(l10n, error)))
```

**⑤ 클라 자체 오류 문구 9개도 같은 방식으로 처리한다.**
`dio_client`(4) · `chat_provider`(2) · `onboarding_provider`(2) · `session_provider`(1).
네트워크 타임아웃·연결 실패처럼 **서버가 응답조차 못 준 경우**이므로, `ApiException`에
`code: 'NETWORK_TIMEOUT'` / `'NETWORK_UNREACHABLE'` / `'NETWORK_UNKNOWN'` 같은 **클라 전용 코드**를 실어
같은 매핑 함수를 타게 한다. `message`에는 지금 문구를 남겨 둔다(폴백 겸 로그용).

### 2-4. 코드 이름 초안

54개 메시지를 실제로 읽고 뽑은 것이다. **그대로 쓰라는 게 아니라 재조사 시간을 아끼라는 것** —
서버 코드를 열어 확인하고 필요하면 고칠 것.

| 도메인 | 제안 코드 | 지금 메시지 |
|---|---|---|
| 공통 | `USER_NOT_FOUND` | 사용자를 찾을 수 없습니다. (6곳) |
| auth | `PROVIDER_DISABLED` *(기존)* | {provider} 로그인은 현재 비활성화되어 있습니다. |
| profile | `NICKNAME_DUPLICATE` *(기존)* | 이미 사용 중인 닉네임입니다. |
| profile | `NICKNAME_INVALID` *(기존)* | 사용할 수 없는 닉네임입니다. |
| profile | `NICKNAME_FORMAT` | 닉네임은 특수문자·이모지 없이 10자 이내여야 합니다. |
| profile | `AGE_RESTRICTED` | 만 18세 이상만 가입할 수 있습니다. |
| post | `POST_GATE_CLOSED` | 지금은 포스트를 등록할 수 있는 시간이 아니에요. |
| post | `POST_UPLOAD_WINDOW_CLOSED` | 포스트 등록 가능 시간이 종료되었어요. |
| post | `POST_ONELINER_REQUIRED` | 하루 한 마디를 입력해 주세요. |
| post | `POST_PHOTO_REQUIRED` | 새로운 포스트 사진을 등록해 주세요. |
| post | `POST_PHOTO_NOT_FOUND` | 사진을 찾을 수 없습니다. |
| post | `POST_PHOTO_NOT_MINE` | 내 사진만 삭제할 수 있습니다. |
| post | `POST_PHOTO_LIMIT` | 등록 가능한 포스트 사진 수를 초과했습니다… |
| post | `POST_REPLACE_LIMIT` | 오늘의 사진 교체 횟수를 모두 사용하였습니다… |
| post | `POST_REPLACE_FREE_LIMIT` | 무료로 하루에 2장까지 교체할 수 있습니다… |
| post | `POST_NOT_PUBLISHED_TODAY` | 오늘 등록된 포스트가 없어요. |
| garden | `GARDEN_GATE_CLOSED` | 달빛가든은 아직 문을 열지 않았어요… |
| garden | `GARDEN_TARGET_BLOCKED` | 현재 이 사용자에게 댓글을 남길 수 없어요. |
| chat | `CHAT_GATE_CLOSED` | 달빛이 찾아오는 오후 5시부터… 대화할 수 있어요. |
| chat | `CHAT_SELF` | 자신에게는 대화를 신청할 수 없어요. |
| chat | `CHAT_TARGET_BLOCKED` | 현재 이 사용자에게 대화 신청을 보낼 수 없어요. |
| chat | `CHAT_REQUEST_PENDING` | 이미 대화를 신청했어요. 상대의 응답을 기다려 주세요. |
| chat | `CHAT_REQUEST_NOT_FOUND` | 신청을 찾을 수 없어요. |
| chat | `CHAT_REQUEST_ALREADY_HANDLED` | 이미 처리된 신청이에요. |
| chat | `CHAT_ACCEPT_NOT_RECEIVER` | 내가 받은 신청만 수락할 수 있어요. |
| chat | `CHAT_REJECT_NOT_RECEIVER` | 내가 받은 신청만 거절할 수 있어요. |
| chat | `ROOM_ALREADY_ACTIVE` *(기존)* | 이미 진행 중인 대화가 있어요. |
| chat | `CHAT_ROOM_NOT_FOUND` | 대화방을 찾을 수 없어요. |
| chat | `CHAT_ROOM_CLOSED` | 종료된 대화방이에요. |
| chat | `CHAT_NOT_MEMBER` | 참여 중인 대화방이 아니에요. |
| friend | `FRIEND_SELF` | 자신에게는 친구 요청을 보낼 수 없어요. |
| friend | `FRIEND_TARGET_BLOCKED` | 현재 이 사용자에게 친구 요청을 보낼 수 없어요. |
| friend | `FRIEND_ALREADY` | 이미 친구예요. |
| friend | `FRIEND_NOT_YET` | 아직 친구가 아니에요. |
| friend | `FRIEND_NOT_MINE` | 내 친구 관계가 아니에요. |
| friend | `FRIEND_REQUEST_PENDING` | 이미 친구 요청이 오갔어요. 응답을 기다려 주세요. |
| friend | `FRIEND_REQUEST_ALREADY_ACCEPTED` | 이미 친구가 된 요청이에요. |
| friend | `FRIEND_REQUEST_NOT_FOUND` | 친구 요청을 찾을 수 없어요. |
| friend | `FRIEND_ACCEPT_NOT_RECEIVER` | 내가 받은 요청만 수락할 수 있어요. |
| friend | `FRIEND_REJECT_NOT_RECEIVER` | 내가 받은 요청만 거절할 수 있어요. |
| friend | `FRIEND_CANCEL_NOT_SENDER` | 내가 보낸 요청만 취소할 수 있어요. |
| friend | `FRIEND_LIMIT_EXCEEDED` | 친구는 최대 N명까지예요. ⚠️ **placeholder 필요** |
| friend | `FRIEND_NO_TODAY_POST` | 친구가 아직 오늘의 포스트를 공유하지 않았어요. |
| store | `LUNA_INSUFFICIENT` *(기존)* | (루나 부족) |
| store | `STORE_PRODUCT_NOT_FOUND` | 존재하지 않는 상품이에요. |
| store | `STORE_PRODUCT_INVALID` | 상품 구성이 잘못됐어요. |
| store | `STORE_BOOST_NONE` | 보유한 부스트가 없어요. |
| store | `STORE_BOOST_ALREADY_ACTIVE` | 이미 사용 중인 부스트예요. |
| store | `STORE_ALREADY_SUBSCRIBED` | 이미 프라임 구독 중이에요. |
| store | `STORE_NOT_SUBSCRIBED` | 구독 중이 아니에요. |
| store | `STORE_ALREADY_CANCELED` | 이미 자동갱신을 해지했어요. |
| store | `STORE_RECEIPT_INVALID` | 결제 정보를 확인할 수 없어요. |
| store | `STORE_PURCHASE_FAILED` | 현재 결제를 처리할 수 없어요. |
| moderation | `MODERATION_SELF` | 자기 자신은 대상이 될 수 없어요. |
| moderation | `TARGET_BLOCKED_OR_REPORTED` *(기존)* | (차단·신고된 대상) |
| 클라 전용 | `NETWORK_TIMEOUT` / `NETWORK_UNREACHABLE` / `NETWORK_UNKNOWN` | dio_client 3종 |

⚠️ **`FRIEND_LIMIT_EXCEEDED`는 서버가 `"친구는 최대 " + n + "명까지예요."`로 문자열을 이어 붙이고 있다.**
숫자를 `field`나 별도 응답 필드로 실어 보내고 **클라 ARB에서 placeholder로 조립**해야 한다.
일본어는 `友だちは最大N人までです。`라 조각 순서가 달라진다.

### 2-5. 권장 진행 순서

한 번에 하면 서버·클라가 동시에 흔들려 어디가 깨졌는지 못 찾는다. **작게 나눠 커밋할 것.**

1. **서버 `ErrorCode` 확장** — enum에 코드를 추가하고, `new ApiException(...)` 62곳의 코드를 바꾼다.
   메시지는 **그대로 둔다**. 이 커밋만으로는 앱 동작이 하나도 안 바뀐다(= 안전하다).
   ✅ 확인: 서버 재기동 + 앱에서 오류 상황 몇 개 발생시켜 응답 `code`가 세분화됐는지 본다.
2. **클라 매핑 뼈대** — `lib/core/error/error_messages.dart` 신설 + ARB `errorXxx` 키 추가.
   프로바이더 `_run` 헬퍼 7개의 반환 타입을 `ApiException?`으로 바꾸고, 화면 22곳 호출부를 고친다.
   이때 매핑은 **비어 있어도 된다**(전부 `_ => e.message` 폴백). 배관만 먼저 통과시키는 단계.
   ✅ 확인: `flutter analyze lib` 0건 + 앱에서 오류 문구가 **전과 똑같이** 나오는지.
3. **도메인별로 문구 이전** — chat → friend → post → store → 나머지 순으로 나눠 커밋.
   ARB에 한·일 문구를 넣고 매핑 `switch`에 줄을 추가한다.
4. **클라 자체 오류 9개**를 같은 매핑에 태운다.
5. **테스트 추가** — `test/l10n_test.dart`에 "`ErrorCode`에 있는 코드가 전부 매핑돼 있는가"를 넣는다.
   (서버 enum과 클라 매핑이 어긋나는 걸 잡아 주는 유일한 안전장치다.)

### 2-6. 완료 기준

- [ ] 서버 `ErrorCode` 세분화 완료, `VALIDATION_FAILED`/`NOT_FOUND`는 **최후 폴백으로만** 남음
- [ ] 클라 매핑 함수 한 곳(`error_messages.dart`)에서 전 코드 처리, 미매핑은 `e.message` 폴백
- [ ] 프로바이더가 `String?` 대신 `ApiException?` 반환, 화면 22곳 반영
- [ ] `app_ko.arb`/`app_ja.arb`에 `errorXxx` 키 추가(양쪽 동수 유지)
- [ ] `flutter analyze lib` 0건 · `flutter test` 통과
- [ ] **에뮬레이터를 `ja-JP`로 놓고 오류를 실제로 띄워 일본어로 나오는지 확인**
      (게이트 닫힌 상태에서 대화 신청 / 이미 친구인 사람에게 친구 요청 / 루나 부족 상태로 구매)

---

## 3. 그다음 (이 작업이 끝나면)

**③단계 — 일본어 마감**
- **원어민 검수.** 지금 `app_ja.arb` 378키는 전부 AI 초벌이다. 매칭 앱은 문구 뉘앙스가 매출로 이어진다.
- **Noto Sans JP 폰트** 추가 여부 — 일본어 한자 중 한국 폰트에 없는 글자가 두부(□)로 보일 수 있다
  ([08 체크리스트](08-assets-checklist.md) 미결 항목).
- (선택) 앱 내 언어 전환 UI. 지금은 기기 언어를 따른다. `MaterialApp.locale`에 주입하면 되도록 자리는 열어 뒀다.
- ⚠️ **로그인 배경 이미지에 한국어가 구워져 있다.** 코드로는 못 고친다 — 글자 없는 배경을 새로 받아야 한다.

**그 외 남은 것**은 [04 로드맵](04-progress-and-roadmap.md) 참고. 큰 것 둘:
- **실시간 AI 번역** — 껍데기만 있다. `TRANSLATE_PASS`를 800루나에 팔면서 **혜택이 실제로 없다**(BM 구멍).
  번역 API 키 없이도 **쿼터·패스 판정은 먼저 붙일 수 있다.**
- **앱 아이콘·스플래시** — 아직 Flutter 기본값.

---

## 4. 작업 시작 전 체크

```bash
git pull origin main
```

그다음 [07](07-work-log.md) §2-2 "매번 — 개발 시작 루틴"대로:
MariaDB 기동 → 서버 `bootRun` → `adb reverse tcp:8080 tcp:8080` → `flutter run`.

**낮에 작업한다면** 게이트가 닫혀 있어 대부분의 기능이 막힌다. §2-4의 우회 방법을 쓸 것
(`--args='--app.gate.open-hour=0'`으로 항상 열어 두기). 다만 이번 작업은 **오류 문구**가 대상이라
**게이트를 일부러 닫아 두는 편이 오히려 테스트하기 좋다.**

**작업이 끝나면**: 이 문서를 다음 작업 내용으로 갈아끼우고, [07](07-work-log.md) §4에 세션 로그를 추가하고,
[04](04-progress-and-roadmap.md) 체크박스를 갱신할 것.
