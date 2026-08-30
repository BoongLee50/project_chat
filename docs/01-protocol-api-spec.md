# 달빛톡 — 통신 프로토콜 & API 명세 (초안)

> 기준 기획: **Plan_2**(2026-07-30). 운영시간 **17:00 개방 ~ 06:00 종료**(친구목록·친구 대화방은 24시간).
> 운영시간은 **서버가 강제**한다(post·garden·chat의 `requireGateOpen()`). 클라의 화면 분기는 보조일 뿐이므로,
> 시간 제한이 필요한 새 API에는 반드시 서버측 검사를 함께 넣을 것. 상점/구독(BM)은 §1.8, 친구는 양방향(요청/수락).
> 상태: **설계 초안**. 서버 스택 **확정**(Spring Boot + MariaDB/MyBatis + Redis(선택 구성)). 채팅 보관정책은 **확정**(방 타입 기준 — 매칭 30일 / 친구 1년, FIFO 삭제. 클라 "대화 삭제"는 UI만 — [02 스키마](02-db-schema.md) 참고). 기획서 화면 기준으로 매핑.
> 통신 분리 원칙: **소켓(WebSocket)=실시간 양방향/푸시**, **REST(패킷)=단발 요청-응답**.

공통 규약
- 전송: REST = `HTTPS + JSON`, 실시간 = `WSS`
- 인증: `Authorization: Bearer <accessToken>` (JWT). 소켓은 연결 직후 `AUTH` 패킷으로 검증.
- 시간: 모든 시간 판정은 **서버 권위(KST)**. 클라 시간 신뢰 안 함.
- 에러 응답: `{ "code": "STRING_CODE", "message": "...", "field": "optional" }`
- 페이징: 커서 방식 `?cursor=<opaque>&limit=<n>`

---

## 1. REST API (패킷)

### 1.1 인증 / 게이트
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| POST | `/auth/social` | 소셜 로그인(provider, providerToken) → JWT 발급 + 회원상태 | 1,2 |
| POST | `/auth/refresh` | accessToken 재발급(refreshToken) | - |
| GET | `/system/gate` | 현재 오픈 여부/다음 오픈시각 (**17시 개방~06시 종료**) | 1 |

`POST /auth/social` 응답 예:
```json
{ "status": "NEW | PROFILE_REQUIRED | ACTIVE | BANNED",
  "accessToken": "...", "refreshToken": "...",
  "user": { "id": "...", "nickname": null } }
```
- `BANNED` → 클라는 [MSG NUM1] 출력 후 로그인 종료.
- provider별 client-id/secret/검증 URL과 사용 여부(`app.auth.social.{provider}.enabled`)는 서버 설정 파일로 관리. 키가 아직 없는 provider는 `enabled: false`로 꺼두고, 발급되는 대로 설정만 켜서 순차 오픈. [05 서버구조 §9.1](05-server-structure.md#91-소셜-로그인-실-구현-설정-파일-기반) 참고.

### 1.2 온보딩 / 프로필
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| GET | `/profile/nickname:check?value=` | 닉네임 검증(특수문자/10자/중복/금지어) | 3 |
| POST | `/profile` | 프로필 생성(nickname, birthYear, gender, country) | 3,4,5 |
| GET | `/me` | 내 프로필 조회 | 20 |
| POST | `/me/profile-photo:upload-url` | 프로필 사진 업로드 URL 발급 | 21 |
| PUT | `/me/profile-photo` | 업로드 완료 후 사진 등록(storageKey) — storageKey 생략 시 제거 | 21 |
| PUT | `/me/interests` | 관심사(최대 8) | 22 |
| PUT | `/me/intro` | 소개 한마디(최대 50자) | 23 |
| PUT | `/me/regions` | 지역(최대 2) | 24 |
| GET | `/users/:id/profile` | 상대 프로필 조회 | 14,19 |

검증 규칙: 닉네임 특수문자·이모지 불가/≤10자/중복·금지어, 가입 만 18세 이상.
프로필 사진은 포스트 사진(§1.3)과 동일한 흐름 — 업로드 URL 발급 → 클라가 그 URL로 직접 업로드 → `storageKey`로 등록. `GET /me`/`GET /users/:id/profile` 응답에는 다운로드 URL이 이미 포함되어 내려옴(05 서버구조 §8 참고).

### 1.3 오늘의 포스트 (사진은 Storage 직접 업로드)
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| POST | `/posts/photos:upload-url` | presigned 업로드 URL 발급 | 6 |
| POST | `/posts/photos` | 업로드 완료 후 사진 등록(storageKey) | 6 |
| DELETE | `/posts/photos/:id` | 포스트 사진 삭제(= 교체 1회 소모) | 6 |
| POST | `/posts/photos/:id:main` | **대표 사진 지정**(달빛가든 노출) | 6 |
| GET | `/posts/me` | 내 오늘 포스트(사진·대표 사진·남은 한도) | 6 |
| POST | `/posts:publish` | 포스트 공유하기(사진 1장 이상 필요) | 6 |

**제한(Plan_3)**: 사진 무료 2장 / 앨범패스 **9장**, 교체는 양쪽 다 **3회**.
운영시간이 폐지돼 **등록 시간 제한은 없다** — 영업일(KST 18시 경계) 안이면 언제든 올린다.
한도에 걸리면 서버가 `field`에 **숫자를 실어 보내고**(`POST_PHOTO_LIMIT`·`POST_REPLACE_*`)
클라가 ARB 문구에 끼운다. 설정값이 바뀌어도 문구가 거짓말이 되지 않는다.

**대표 사진(`mainPhotoId`)** — 달빛가든 카드의 첫 장이자, ③단계 열람 제한의 기준이다.
- 최초 사진은 **자동 메인**. 메인을 지우면 **이웃 슬롯이 승계**(다음 슬롯, 없으면 직전 슬롯).
- 사진 표시 순서는 **최신이 1번 슬롯**이다(`GET /posts/me`가 그 순서로 준다).
- `posts.main_photo_id`에는 **FK가 없다**(순환 캐스케이드 회피 — V11). 서버가 읽을 때
  실재를 확인해 떠 있으면 첫 슬롯으로 대신하므로, 클라는 받은 값을 그대로 믿으면 된다.
> 업로드 대상(S3/로컬 디스크)은 서버 설정(`app.storage.type`)에 따라 전환 — 클라이언트는 동일한 업로드 URL 발급 흐름만 사용. [05 서버구조 §8](05-server-structure.md#8-파일-스토리지-추상화-s3--로컬-디스크) 참고.

### 1.4 달빛가든 (피드/댓글)
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| GET | `/feed?gender=&age=&country=&cursor=` | 스코어순 피드(필터) | 7 |
| POST | `/feed/:userId/like` | 좋아요 +1 (스코어/전환율 반영) | 7 |
| POST | `/feed/:userId/skip` | 스킵 처리 | 7 |
| GET | `/posts/:userId/comments` | 포스트 댓글 목록(**트리 순서**) | 9 |
| POST | `/posts/:userId/comments` | 댓글/답글 작성(≤50자, **3단계**, 이미지 1장) | 9 |
| POST | `/posts/comments/image:upload-url` | 댓글 첨부 이미지 업로드 URL | 9 |
| POST | `/translate` | 번역(text, targetLang, **scope**, targetId) 한↔일 | 9 |

필터 기본값 [전체]. 수치는 전부 `app.garden.*` 설정이다(`GardenProperties`).

**Post Score(Plan_3 4-1)** = `Online + Recency + Engage`
```
Online  : 접속 중 10 / 미접속 0
Recency : 1h 이내 30 / 1~3h 20 / 3~5h 10 / 5h 초과 0
          기준은 **공유 시각과 사진 갱신 시각 중 나중**("사진 갱신 시에도 적용")
Engage  : {(좋아요×1)+(댓글×2)+(대화신청×4)} / 총 노출 × 100
          30%↑ 30 / 20%↑ 20 / 15%↑ 15 / 10%↑ 10 / 5%↑ 5 / 그 외 0
          * 총 노출 20회 미만이면 0
```
🚨 **Pick Point(부스트 가점)는 폐지됐다.** 부스트는 점수가 아니라 **풀을 나눈다** —
일반 풀과 부스트 풀을 각각 정렬해 **6:4로 섞어** 내보낸다(부스트 풀이 더 크면 비율이 뒤집힌다).
응답의 `pick`은 PICK 마크 **표시용**이지 가점이 아니다. 광고의 "10배"는 이론상 최대 배수다.

**노출 순서는 진입할 때 한 번만 정한다**(`FeedSessionStore`, 기본 30분 유지).
커서가 없으면 새로 산정하고, 있으면 그때의 순서를 이어서 자른다 — 그래서 페이지가 어긋나지 않는다.
필터가 바뀌거나 끝까지 보면(풀 소진) 다시 산정한다. 순서는 **메모리에만** 있다(프레즌스와 같은 성격).

**한 번 보여준 상대는 15분간 후보에서 빠진다**(`feed_exposures`, V12). 스킵(`feed_skips`)과 다른 개념이다 —
넘기지 않고 지나간 상대도 잠시 안 나와야 같은 얼굴이 연달아 뜨지 않는다.
볼 게 다 떨어지면 스킵·15분을 모두 풀고 다시 채운다.

**열람 제한(Plan_3 4-1)** — 무료 사용자는 상대의 **메인 사진 1장만** 본다.
오늘 자기 포스트에 사진을 올리고 **[공유하기]까지** 하면 열린다(앨범패스·프라임은 항상 무제한).
⚠️ **자르는 일은 서버가 한다** — 잠긴 사진의 URL은 응답에 담기지 않는다. 화면에서만 가리면
API를 직접 부르는 것으로 뚫린다. 응답에 `photoLocked`(잠김 여부)와 `totalPhotos`(원래 장수)가 실려
클라가 "몇 장이 더 있다"를 안내할 수 있다.
**댓글(Plan_3 4-2 / 8-2 / 8-3)** — 세 화면의 규칙이 **완전히 같아** 한 구조를 쓴다.
- **3단계까지**(댓글/대댓글/대대댓글). 그 이상은 `COMMENT_DEPTH_EXCEEDED`(409).
- **50자**까지. 넘으면 `COMMENT_TOO_LONG`(400) — 숫자는 `field`로 실어 보내 ARB가 문장을 만든다.
- **이미지 1장**. 포스트 사진과 같은 흐름(URL 발급 → 직접 업로드 → `imageKey`로 등록).
  키에 업로더 id가 들어 있어 **남의 키를 붙이면** `COMMENT_IMAGE_KEY_INVALID`(403).
- 목록은 서버가 **트리 순서로 평탄화**해 준다 — 부모 바로 뒤에 그 답글이 온다.
  클라는 `depth`만큼 들여쓰면 되고 재귀 조립을 하지 않는다.
- 수치는 `app.comment.max-length` · `app.comment.max-depth`.
- Engage 집계(`post_stats.comments`)는 **답글도 댓글로 센다**.

⚠️ **번역 무료 단위가 기획서와 다르다(⑦단계 확인 대상)** — 지금은 `free-comments-per-day: 2`(번역 **건수**)인데
기획서 4-2·8-2는 *"댓글창 **5회 호출**까지 무료"* 다. **값(2→5)뿐 아니라 세는 단위가 다르다.**

`/translate`는 번역 API 키 설정 전엔 원문을 그대로 반환하는 패스스루로 동작(`app.translate.provider=none`), 추후 실제 번역 공급자로 전환. [05 서버구조 §9.2](05-server-structure.md#92-번역) 참고.
무료 번역 쿼터(Plan_2): **댓글 하루 2회 / 채팅 매일 2명**, 초과 시 자동번역패스 유도. **자동번역패스**(TRANSLATE_PASS) 보유 시 무제한. 프로필 보기는 항상 무료. 프라임 구독은 번역 무제한.

**구현됨(V7).** 요청은 `{ text, targetLang, scope, targetId? }` — `scope`는 `COMMENT|CHAT|PROFILE`이고
`CHAT`일 때만 `targetId`(상대 userId)가 필요하다(없으면 `TRANSLATE_TARGET_REQUIRED`).
응답은 `{ text, provider, unlimited, remaining }` — `remaining`은 **소진 전에** 패스를 권하라고 주는 값이다.
쿼터 초과는 `TRANSLATE_QUOTA_EXCEEDED`(409).
댓글은 횟수라 `daily_usage.COMMENT_TRANSLATE`를 쓰지만, 채팅의 "2명"은 카운터로 셀 수 없어
**상대를 행으로 남기는 `daily_translate_targets`(V7)** 를 쓴다 — 한 번 연 상대와는 그날 계속 무료.
둘 다 06시 배치가 지난 영업일을 정리한다.

### 1.5 대화 신청 (하이브리드: 생성=REST, 도착알림=소켓)
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| POST | `/chat-requests` | 대화 신청(targetUserId, message ≤100자) — **루나 5 차감 트랜잭션** | 10 |

**하루 무료 2회**(daily_usage, [02 §1.7](02-db-schema.md)) 후 건당 루나 5 차감. 프리미엄(프라임 구독)은 무제한·무차감.
실패: 루나 부족 [MSG NUM1] / 차단·신고 대상 [MSG NUM2].
성공 시 서버가 상대에게 `CHAT_REQ_INCOMING` 소켓 푸시 + 내 [보낸신청] 목록 생성.

### 1.6 대화방 (초기 로드=REST, 갱신=소켓)
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| GET | `/chat/rooms` | 매칭 대화 + 받은 신청 목록 | 11 |
| GET | `/chat/rooms/sent` | 보낸 신청 목록 | 12 |
| GET | `/chat/rooms/:id/messages?cursor=` | 대화 히스토리(페이징) | 13 |
| POST | `/chat/rooms/:id:accept` | 신청 수락 → 매칭 대화로 이동 | 11 |
| POST | `/chat/rooms/:id:reject` | 신청 거절 | 11 |
| POST | `/chat/rooms/:id:leave` | 대화방 나가기(종료) | 15 |

종료/차단/신고된 항목은 목록에서 제거, `대화 종료` 마크 30분 후 삭제.
> 종료된 방은 재사용되지 않음 — 같은 상대와 다시 매칭되면 새 `roomId`로 새 대화방이 생성됨(02 스키마 §1.5 참고). 클라는 roomId를 상대 userId 기준으로 캐싱하지 말 것.

### 1.7 친구 / 신고·차단 / 루나
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| GET | `/friends?gender=&ageMin=&ageMax=&country=` | 친구 목록(수락 최신순, ACCEPTED). 응답에 `roomId`(상시 대화방)·`online` 포함 | 18 |
| GET | `/friends/requests` | 받은 친구 요청 목록(PENDING) | 18 |
| GET | `/friends/requests/sent` | 보낸 친구 요청 목록(PENDING) | 18 |
| POST | `/friends/requests` | 친구 **요청**(targetUserId) — 양방향, 상대 수락 필요 | 14,18 |
| POST | `/friends/requests/:id:accept` | 친구 요청 수락 → **상시 대화방 생성**(응답 `{friendshipId, roomId}`) | 18 |
| POST | `/friends/requests/:id:reject` | 친구 요청 거절(행 삭제 — 다시 요청 가능) | 18 |
| POST | `/friends/requests/:id:cancel` | 보낸 요청 취소 | 18 |
| DELETE | `/friends/:id` | 친구 삭제 — 상시 대화방도 함께 종료 | 19 |
| GET | `/friends/:id/today-post` | 친구 오늘의 포스트 팝업. `:id`는 **friendshipId**(당사자만 조회 가능). 공유 전이면 404 | 19 |
| POST | `/reports` | 신고(targetUserId, **reason 코드**, detail?) | 16 |
| POST | `/blocks` | 차단(targetUserId) — 이미 차단한 상대여도 200(멱등) | 17 |
| GET | `/luna/balance` | 보유 루나 | 6 |
| POST | `/luna/charge` | 루나 충전(결제) | 6 |

**신고 사유 코드**(화면 16): `ILLEGAL_AD`(불법 광고 및 홍보) · `ROMANCE_SCAM`(로맨스 스캠) · `SEXUAL_DEEPFAKE`(허위 합성/편집한 성인물) · `ABUSIVE`(욕설 및 비매너) · `COERCION`(강요 및 협박) · `PRIVACY_LEAK`(개인정보 유출) · `OTHER`(기타 — `detail` 필수).
화면 문구가 바뀌어도 저장값이 흔들리지 않도록 **코드로 보낸다**. `OTHER`면 `reason: detail` 형태로 합쳐 저장.

**신고·차단 부수효과(둘 다 동일)**: 친구 관계 즉시 해제 + 살아있는 대화방 종료(MATCH·FRIEND 모두) + 상대에게 `FRIEND_STATE(removed)` · `ROOM_STATE(ended)` 소켓 통지. 이후 그 상대에게는 대화 신청·친구 요청이 막힌다. 신고 사실 자체는 상대에게 알리지 않는다.

**음성 메시지**(2026-08-23) — 바이트는 소켓을 지나지 않는다.
1. `POST /chat/rooms/{roomId}/voice:upload-url?contentType=audio/mp4` → `{ uploadUrl, storageKey }`
2. 그 `uploadUrl`로 파일 **PUT**(로컬 스토리지 모드에서는 우리 서버라 인증 헤더 필요)
3. 소켓 `CHAT_SEND`에 `type=VOICE` + `audioKey`(= 위 `storageKey`) + `audioDurationMs`
- `storageKey`는 `chat-voice/{보낸사람 id}/…` 형태이고, 서버가 **보내는 사람의 경로인지 확인**한다(남의 key 차단).
- 길이는 서버가 `app.chat.voice-max-duration-ms`(기본 30초)로 검사한다. 인코더 여유분 1초를 더 허용한다.
- ⚠️ **무료 5회 제한은 아직 없다**(기획 예정). 지금은 횟수 제한 없이 보낼 수 있다.

친구는 **양방향(상호 동의)** — 요청→수락 시 친구가 되며 **24시간 상시 대화방**이 생성됨(야간 게이트/30분 삭제 예외, [02 §1.6](02-db-schema.md)). 최대 친구 수는 설정값(`app.friend.max-count` 20 / `max-count-premium` 30 — 기획서 20 vs 30 모순이라 확정 전까지 잠정). 신고·차단 시 상대는 내 프로필 열람 불가, 친구·대화방 즉시 삭제.

### 1.8 유료 상점 / 구독 / 부스트 (BM, 기획 8장 · 화면 25~30)
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| GET | `/store/products` | 상품 카탈로그(프라임/루나상품/부스트/패스 가격·구성) | 25~30 |
| GET | `/me/wallet` | 내 재화·구독·엔티틀먼트 요약(루나, 구독상태, 활성 패스, 부스트 재고) | 6,25~30 |
| POST | `/store/purchases:verify` | **인앱결제 영수증 검증** → 루나 지급 / 구독 활성화 | 26,27 |
| POST | `/store/webhooks/google` | Google RTDN 수신(갱신·취소·환불) — 서명 검증, `@NoAuth` | - |
| POST | `/store/webhooks/apple` | App Store Server Notifications V2 수신 — 서명 검증, `@NoAuth` | - |
| POST | `/me/subscription:cancel` | 자동갱신 해지(만료까지 유효) | 26 |
| POST | `/store/luna:purchase` | 루나로 개별상품 구매(부스트 매수/앨범패스/번역패스) — 루나 차감 트랜잭션 | 25,28,29,30 |
| POST | `/boosts:use` | 보유 부스트 사용(kind: POST/SPOTLIGHT) → 1시간 활성 | 28 |

**결제 흐름 (중요)** — 클라가 "샀다"고 말하는 것을 믿지 않는다.
```
① 클라: 스토어 결제창(in_app_purchase) → purchaseToken/영수증 획득
② 클라 → 서버: POST /store/purchases:verify
   { platform: GOOGLE|APPLE, productId, purchaseToken }
③ 서버: Google Play Developer API / App Store Server API로 **직접 검증**
   → 유효하면 루나 지급 또는 subscriptions/user_entitlements 활성화(02 §1.7)
   → purchaseToken을 저장해 **중복 지급 방지**(멱등)
④ 이후 갱신/취소/환불은 스토어 **웹훅**으로 수신해 상태 동기화
```
- **IAP 대상**: 현금이 오가는 것만 — **루나 충전 · 프라임 구독**. 루나로 사는 개별 상품(부스트·앨범패스·번역패스)은 앱 내부 재화 소비라 IAP 불필요(스토어 상품 등록 수를 줄이고, 가격을 서버 설정으로 조정 가능).
- 상품ID·가격은 **스토어 콘솔 + 서버 설정**에서 관리(코드 하드코딩 금지). `GET /store/products`는 카탈로그(구성·혜택)를 내려주고, 실제 표시 가격은 스토어 SDK가 제공하는 현지 가격을 쓰는 것이 원칙.
- LINE은 **로그인 provider일 뿐 결제 수단이 아님**(디지털 재화는 스토어 결제 강제).
- 광고 제거 혜택 → 광고 SDK(AdMob 등) 연동 필요.
- ⚠️ 인앱결제 정책·수수료·외부결제 허용 범위는 **국가별/시기별로 변동**되므로, BM 확정 시점에 각 스토어 최신 정책을 재확인할 것.
- **구현 상태(2026-08)**: 카탈로그·지갑·루나 개별구매·부스트 사용·구독 해지·영수증 검증(멱등)까지 동작. **영수증 실검증과 웹훅 서명 검증은 스토어 계정이 없어 미구현** — 개발용 `MockReceiptVerifier`(`app.store.mock-purchase-enabled`, local 전용)가 `dev-` 토큰만 통과시킨다. 웹훅은 200으로 받되 **상태를 바꾸지 않는다**(서명 검증 없이 본문을 믿으면 남의 구독을 조작할 수 있으므로).
- 혜택 판정은 [02 §1.7](02-db-schema.md) `subscriptions`/`user_entitlements`/`boost_inventory` 기준. `/me/wallet`이 클라가 화면(PASS 표시·버튼 상태)에 쓸 상태를 한 번에 내려줌.
- 프라임/앨범패스 보유자는 §1.3 포스트(8장·시간무제한·갤러리)·§1.4 열람 제한 해제. 부스트 활성 시 §1.4 Post Score의 Pick Point 반영.

---

## 2. WebSocket 실시간 프로토콜 (소켓 패킷)

### 2.1 봉투(Envelope)
```json
{ "op": "CHAT_SEND", "seq": 1024, "ts": 1720800000, "data": { } }
```
- `op`: opcode(패킷 종류) · `seq`: 클라 시퀀스(ACK 매칭·중복방지) · `ts`: 타임스탬프 · `data`: 페이로드
- 연결 유지: `PING/PONG` heartbeat. 밤샘 사용 대비 자동 재연결 + `seq` 기반 유실 복구.
- 서버 다중화: room 전달은 Redis Pub/Sub으로 노드 간 브로드캐스트(Redis 활성화 시).
- Redis는 선택 구성(설정으로 on/off). 비활성화 시(단일 인스턴스 운영 기준) 프레즌스·피드 랭킹은 인메모리/DB 직접 조회로 대체되어 서비스 동작에는 지장 없음. 다만 서버를 여러 대로 수평 확장하면 인스턴스 간 소켓 브로드캐스트·프레즌스 동기화를 위해 Redis가 사실상 필요.

### 2.2 Opcode 목록
| 방향 | op | data(요약) | 용도 |
|------|----|-----------|------|
| C→S | `AUTH` | `{ accessToken }` | 연결 직후 인증 |
| S→C | `AUTH_OK` / `AUTH_FAIL` | `{}` / `{code}` | 인증 결과 |
| C→S | `PING` / S→C `PONG` | `{}` | heartbeat/프레즌스 |
| C→S | `ROOM_SUBSCRIBE` | `{ roomId }` | 채팅창 진입 |
| C→S | `CHAT_SEND` | `{ roomId, type?, body, audioKey?, audioDurationMs?, seq }` | 메시지 전송. `type`은 `TEXT`(기본)/`VOICE` |
| S→C | `CHAT_SENT_ACK` | `{ seq, messageId, type, audioUrl, audioDurationMs, ts }` | 전송 확인 |
| S→C | `CHAT_RECV` | `{ roomId, messageId, senderId, type, body, audioUrl, audioDurationMs, ts }` | 메시지 수신 |
| C→S | `CHAT_READ` | `{ roomId, lastMessageId }` | 읽음 처리 |
| S→C | `CHAT_READ_RECEIPT` | `{ roomId, readerId, lastMessageId }` | 읽음 수신 |
| S→C | `CHAT_REQ_INCOMING` | `{ requestId, fromUser }` | 새 대화 신청 도착 |
| S→C | `FRIEND_REQ_INCOMING` | `{ friendshipId, fromUserId, fromNickname }` | 새 친구 요청 도착 |
| S→C | `FRIEND_STATE` | `{ friendshipId, state: accepted\|rejected\|cancelled\|removed, roomId? }` | 친구 관계 변화 |
| S→C | `ROOM_STATE` | `{ roomId, state: accepted\|rejected\|ended }` | 대화방 상태 변화 |
| S→C | `PRESENCE_UPDATE` | `{ userId, online }` | 상대 온/오프라인 |
| S→C | `UNREAD_COUNT` | `{ roomId, count }` | 미확인 N 갱신 |
| S→C | `SYSTEM_CLOSE` | `{ closeAt }` | 05시 종료 임박/강제종료 |
| S→C | `ERROR` | `{ code, message, seq? }` | 오류 |

### 2.3 소켓 vs REST 요약
- 🔌 소켓: 채팅 송수신, 대화방 상태변화, 대화신청·친구요청 수신알림, 친구 관계 변화, 프레즌스, 미확인 카운트, 시스템 종료.
- 📦 REST: 인증, 프로필, 포스트(+사진 업로드), 피드/댓글, 대화신청 생성(루나), 목록/히스토리 조회, 친구, 신고·차단, 루나.
- 하이브리드: **대화 신청**(생성 REST → 도착 소켓), **대화방 목록**(초기 REST → 갱신 소켓).
