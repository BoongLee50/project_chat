# 달빛톡 — 통신 프로토콜 & API 명세 (초안)

> 상태: **설계 초안**. 서버 스택(NestJS 추천)·채팅 보관정책은 잠정. 기획서 화면 기준으로 매핑.
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
| GET | `/system/gate` | 현재 오픈 여부/다음 오픈시각 (18~05시) | 1 |

`POST /auth/social` 응답 예:
```json
{ "status": "NEW | PROFILE_REQUIRED | ACTIVE | BANNED",
  "accessToken": "...", "refreshToken": "...",
  "user": { "id": "...", "nickname": null } }
```
- `BANNED` → 클라는 [MSG NUM1] 출력 후 로그인 종료.

### 1.2 온보딩 / 프로필
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| GET | `/profile/nickname:check?value=` | 닉네임 검증(특수문자/10자/중복/금지어) | 3 |
| POST | `/profile` | 프로필 생성(nickname, birthYear, gender, country) | 3,4,5 |
| GET | `/me` | 내 프로필 조회 | 20 |
| PUT | `/me/profile-photo` | 프로필 사진 설정/제거(URL) | 21 |
| PUT | `/me/interests` | 관심사(최대 8) | 22 |
| PUT | `/me/intro` | 소개 한마디(최대 50자) | 23 |
| PUT | `/me/regions` | 지역(최대 2) | 24 |
| GET | `/users/:id/profile` | 상대 프로필 조회 | 14,19 |

검증 규칙: 닉네임 특수문자·이모지 불가/≤10자/중복·금지어, 가입 만 18세 이상.

### 1.3 오늘의 포스트 (사진은 Storage 직접 업로드)
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| POST | `/posts/photos:upload-url` | presigned 업로드 URL 발급 | 6 |
| POST | `/posts/photos` | 업로드 완료 후 사진 등록(storageKey) | 6 |
| DELETE | `/posts/photos/:id` | 포스트 사진 삭제 | 6 |
| GET | `/posts/me` | 내 오늘 포스트/남은 등록시간 | 6 |
| PUT | `/posts/one-liner` | 하루 한마디(≤25자, 1건 갱신) | 6 |
| POST | `/posts:publish` | 포스트 공유하기(사진+한마디 확정) | 6 |

제한: 일반 사진 2장/구독 8장, 일반 등록시간 30분/구독 무제한. 시간 종료 시 [촬영] 비활성.

### 1.4 달빛가든 (피드/댓글)
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| GET | `/feed?gender=&age=&country=&cursor=` | 스코어순 피드(필터) | 7 |
| GET | `/feed/spotlight?cursor=` | 프리미엄 전용 노출(스코어순) | 7 |
| POST | `/feed/:userId/like` | 좋아요 +1 (스코어/전환율 반영) | 7 |
| POST | `/feed/:userId/skip` | 스킵 처리 | 7 |
| GET | `/posts/:userId/comments` | 포스트 댓글 목록 | 9 |
| POST | `/posts/:userId/comments` | 댓글 작성(≤25자, 대댓글 없음) | 9 |
| POST | `/translate` | 번역(text, targetLang) 한↔일 | 9 |

필터 기본값 [전체]. 노출순 = Post Score 내림차순, 동점은 랜덤.
`Post Score = Pick(프리미엄50) + Online(10/0) + Recency(1h내20/1~3h10/3h초과0) + Engage(전환율 구간별)`.

### 1.5 대화 신청 (하이브리드: 생성=REST, 도착알림=소켓)
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| POST | `/chat-requests` | 대화 신청(targetUserId, message ≤100자) — **루나 5 차감 트랜잭션** | 10 |

실패: 루나 부족 [MSG NUM1] / 차단·신고 대상 [MSG NUM2]. 프리미엄은 루나 미차감.
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

### 1.7 친구 / 신고·차단 / 루나
| Method | Path | 설명 | 화면 |
|--------|------|------|------|
| GET | `/friends?gender=&age=&country=` | 친구 목록(최신순) | 18 |
| POST | `/friends` | 친구 등록(상대 수락 불필요) | 14,18 |
| DELETE | `/friends/:id` | 친구 삭제 | 19 |
| GET | `/friends/:id/today-post` | 친구 오늘의 포스트 팝업 | 19 |
| POST | `/reports` | 신고(targetUserId, reason) | 16 |
| POST | `/blocks` | 차단(targetUserId) | 17 |
| GET | `/luna/balance` | 보유 루나 | 6 |
| POST | `/luna/charge` | 루나 충전(결제) | 6 |

친구 최대 일반 20/프리미엄 무제한. 신고·차단 시 상대는 내 프로필 열람 불가, 친구목록 즉시 삭제.

---

## 2. WebSocket 실시간 프로토콜 (소켓 패킷)

### 2.1 봉투(Envelope)
```json
{ "op": "CHAT_SEND", "seq": 1024, "ts": 1720800000, "data": { } }
```
- `op`: opcode(패킷 종류) · `seq`: 클라 시퀀스(ACK 매칭·중복방지) · `ts`: 타임스탬프 · `data`: 페이로드
- 연결 유지: `PING/PONG` heartbeat. 밤샘 사용 대비 자동 재연결 + `seq` 기반 유실 복구.
- 서버 다중화: room 전달은 Redis Pub/Sub으로 노드 간 브로드캐스트.

### 2.2 Opcode 목록
| 방향 | op | data(요약) | 용도 |
|------|----|-----------|------|
| C→S | `AUTH` | `{ accessToken }` | 연결 직후 인증 |
| S→C | `AUTH_OK` / `AUTH_FAIL` | `{}` / `{code}` | 인증 결과 |
| C→S | `PING` / S→C `PONG` | `{}` | heartbeat/프레즌스 |
| C→S | `ROOM_SUBSCRIBE` | `{ roomId }` | 채팅창 진입 |
| C→S | `CHAT_SEND` | `{ roomId, body(≤25자), seq }` | 메시지 전송 |
| S→C | `CHAT_SENT_ACK` | `{ seq, messageId, ts }` | 전송 확인 |
| S→C | `CHAT_RECV` | `{ roomId, messageId, senderId, body, ts }` | 메시지 수신 |
| C→S | `CHAT_READ` | `{ roomId, lastMessageId }` | 읽음 처리 |
| S→C | `CHAT_READ_RECEIPT` | `{ roomId, readerId, lastMessageId }` | 읽음 수신 |
| S→C | `CHAT_REQ_INCOMING` | `{ requestId, fromUser }` | 새 대화 신청 도착 |
| S→C | `ROOM_STATE` | `{ roomId, state: accepted\|rejected\|ended }` | 대화방 상태 변화 |
| S→C | `PRESENCE_UPDATE` | `{ userId, online }` | 상대 온/오프라인 |
| S→C | `UNREAD_COUNT` | `{ roomId, count }` | 미확인 N 갱신 |
| S→C | `SYSTEM_CLOSE` | `{ closeAt }` | 05시 종료 임박/강제종료 |
| S→C | `ERROR` | `{ code, message, seq? }` | 오류 |

### 2.3 소켓 vs REST 요약
- 🔌 소켓: 채팅 송수신, 대화방 상태변화, 대화신청 수신알림, 프레즌스, 미확인 카운트, 시스템 종료.
- 📦 REST: 인증, 프로필, 포스트(+사진 업로드), 피드/댓글, 대화신청 생성(루나), 목록/히스토리 조회, 친구, 신고·차단, 루나.
- 하이브리드: **대화 신청**(생성 REST → 도착 소켓), **대화방 목록**(초기 REST → 갱신 소켓).
