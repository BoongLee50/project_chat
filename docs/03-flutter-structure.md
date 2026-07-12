# 달빛톡 — Flutter 앱 구조 설계 (초안)

> 상태: **설계 초안**(코드 아님). Feature-first 구조 + 레이어 분리.
> 상태관리 추천: **Riverpod**(riverpod v2). 이유: 이 규모에 적합, 컴파일 안전, DI·비동기·소켓 스트림 관리에 강함. (팀 선호가 Bloc이면 대체 가능)

---

## 1. 폴더 구조 (feature-first)

```
lib/
├─ main.dart                     # 부트스트랩(ProviderScope)
├─ app/
│  ├─ app.dart                   # MaterialApp.router, 테마, 로케일
│  ├─ router.dart                # go_router 라우팅 + 게이트(시간/인증) 리다이렉트
│  └─ theme/                     # 야간 컨셉 다크 테마, 색상, 타이포
├─ core/                         # 앱 전역 공통(도메인 무관)
│  ├─ config/                    # env, 상수, 운영시간(18~05시) 헬퍼
│  ├─ network/
│  │  ├─ dio_client.dart         # REST 클라이언트 + 인터셉터(JWT/refresh/에러)
│  │  ├─ socket_client.dart      # WebSocket 연결/재연결/heartbeat
│  │  ├─ packet.dart             # 봉투 {op,seq,ts,data} 직렬화
│  │  └─ opcodes.dart            # opcode enum(CHAT_SEND 등)
│  ├─ storage/                   # flutter_secure_storage(토큰) / 로컬 캐시
│  ├─ error/                     # Failure/Exception 모델, 매핑
│  └─ utils/                     # 시간(KST), 포매터, validators
├─ features/
│  ├─ auth/                      # 소셜 로그인, 토큰/게이트
│  ├─ onboarding/                # 프로필 생성(닉/출생/성별/나라)
│  ├─ post/                      # 오늘의 포스트(홈), 사진 등록, 하루 한마디
│  ├─ garden/                    # 달빛가든 피드(필터/스와이프/스코어)
│  ├─ comment/                   # 포스트 댓글, 번역
│  ├─ chat/                      # 대화방 목록 + 채팅창(소켓)
│  ├─ friend/                    # 친구 목록/등록/삭제
│  ├─ profile/                   # 내/상대 프로필, 관심사/소개/지역
│  ├─ luna/                      # 보유/충전(결제)
│  └─ moderation/                # 신고/차단
├─ shared/
│  ├─ widgets/                   # 공용 위젯(버튼, 팝업, 사진뷰어)
│  └─ models/                    # 공용 DTO/enum
└─ l10n/                         # 한국어/일본어 다국어 리소스
```

각 feature 내부 3레이어:
```
features/chat/
├─ data/
│  ├─ models/                    # DTO(freezed + json_serializable)
│  ├─ datasources/               # chat_rest_ds.dart / chat_socket_ds.dart
│  └─ repositories/              # ChatRepositoryImpl
├─ domain/
│  ├─ entities/                  # 순수 모델
│  └─ repositories/              # 추상 인터페이스(선택)
└─ presentation/
   ├─ screens/                   # 대화방, 채팅창 화면
   ├─ widgets/
   └─ providers/                # Riverpod controller/notifier
```
> 소규모라면 domain 레이어는 가볍게(엔티티=DTO 겸용) 시작하고, 복잡해지면 usecase 분리.

---

## 2. 네트워킹 레이어 (REST + 소켓 이원화)

- **REST**: `dio` 단일 인스턴스 + 인터셉터
  - 요청 시 accessToken 주입, 401 시 refresh 후 1회 재시도
  - 에러를 `Failure`로 매핑해 상위에 노출
- **소켓**: `web_socket_channel` 래퍼(`socket_client.dart`)
  - 연결 → `AUTH` 패킷 → `AUTH_OK` 확인 후 사용
  - 수신 패킷을 opcode별 **Stream**으로 분배 → feature provider가 구독
  - 끊김 시 지수 backoff 재연결, 재연결 후 미수신분 동기화(`seq` 기반)
  - `PING/PONG` heartbeat로 프레즌스 유지

소켓을 쓰는 feature: `chat`(채팅/대화방 상태), 그리고 수신 알림(`CHAT_REQ_INCOMING`, `UNREAD_COUNT`, `PRESENCE_UPDATE`)은 전역 provider에서 구독해 배지/목록에 반영.

---

## 3. 라우팅 & 게이트

`go_router` redirect로 2단 게이트:
1. **시간 게이트**: `system/gate`가 닫힘 → 대기 화면("오후 6시에 만나요")
2. **인증/온보딩 게이트**: 토큰 없음 → 로그인 / 프로필 미완성 → 온보딩

메인은 홈(오늘의 포스트) 기준, 하단 탭: 달빛가든 · 대화방 · 친구 · 프로필.

---

## 4. 추천 패키지 (pubspec 예정 — 아직 설치 X)

| 용도 | 패키지 |
|------|--------|
| 상태관리/DI | `flutter_riverpod`, `riverpod_annotation` |
| 라우팅 | `go_router` |
| REST | `dio` |
| 소켓 | `web_socket_channel` |
| 모델/직렬화 | `freezed`, `json_serializable`, `json_annotation` |
| 토큰 보관 | `flutter_secure_storage` |
| 이미지 | `image_picker`, `camera`, `cached_network_image`, `image_cropper` |
| 소셜 로그인 | `google_sign_in`, `kakao_flutter_sdk`, LINE SDK(플랫폼 채널) |
| 다국어 | `intl` / `easy_localization` |
| 푸시 | `firebase_messaging` |
| 결제 | `in_app_purchase` (루나 충전) |

> 설치는 실제 구현 단계에서. 지금은 구조/선택만 확정.

---

## 5. 다국어(한↔일) 메모
- UI 문자열은 `l10n`으로 분리(한국어/일본어).
- **콘텐츠 번역**(댓글/채팅)은 서버 `/translate`가 담당(클라 번역 아님). 프리미엄은 자동 번역 on.
