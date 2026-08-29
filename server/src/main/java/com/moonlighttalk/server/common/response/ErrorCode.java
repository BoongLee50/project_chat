package com.moonlighttalk.server.common.response;

/// 클라이언트가 문구를 고르는 기준값. (docs/09 ②단계)
///
/// 서버도 `message`를 계속 내려보내지만, 그건 운영 로그용이자
/// 클라가 아직 매핑하지 않은 코드의 폴백이다. 화면에 보이는 문장은
/// 클라 ARB가 정한다 — 그래야 번역 자원이 한곳에 모인다.
///
/// 이름은 `도메인_상황` 형태. `VALIDATION_FAILED`·`NOT_FOUND`는 지우지 않고
/// **최후 폴백**으로 남긴다(코드를 정하지 않은 새 예외가 떨어질 자리).
public enum ErrorCode {
    // ── 공통 ────────────────────────────────────────────
    UNAUTHORIZED,
    USER_NOT_FOUND,

    // ── auth ───────────────────────────────────────────
    PROVIDER_DISABLED,

    // ── profile ────────────────────────────────────────
    NICKNAME_INVALID,
    NICKNAME_DUPLICATE,
    NICKNAME_FORMAT,
    AGE_RESTRICTED,

    // ── post ───────────────────────────────────────────
    POST_PHOTO_REQUIRED,
    POST_PHOTO_NOT_FOUND,
    POST_PHOTO_NOT_MINE,
    POST_PHOTO_LIMIT,
    POST_REPLACE_LIMIT,
    POST_REPLACE_FREE_LIMIT,
    POST_NOT_PUBLISHED_TODAY,

    // ── garden ─────────────────────────────────────────
    GARDEN_TARGET_BLOCKED,

    // ── translate ──────────────────────────────────────
    TRANSLATE_QUOTA_EXCEEDED,
    TRANSLATE_TARGET_REQUIRED,

    // ── chat ───────────────────────────────────────────
    CHAT_SELF,
    CHAT_TARGET_BLOCKED,
    CHAT_REQUEST_PENDING,
    CHAT_REQUEST_NOT_FOUND,
    CHAT_REQUEST_ALREADY_HANDLED,
    CHAT_ACCEPT_NOT_RECEIVER,
    CHAT_REJECT_NOT_RECEIVER,
    ROOM_ALREADY_ACTIVE,
    CHAT_ROOM_NOT_FOUND,
    CHAT_ROOM_CLOSED,
    CHAT_NOT_MEMBER,

    // ── friend ─────────────────────────────────────────
    FRIEND_SELF,
    FRIEND_TARGET_BLOCKED,
    FRIEND_ALREADY,
    FRIEND_NOT_YET,
    FRIEND_NOT_MINE,
    FRIEND_REQUEST_PENDING,
    FRIEND_REQUEST_ALREADY_ACCEPTED,
    FRIEND_REQUEST_NOT_FOUND,
    FRIEND_ACCEPT_NOT_RECEIVER,
    FRIEND_REJECT_NOT_RECEIVER,
    FRIEND_CANCEL_NOT_SENDER,
    FRIEND_LIMIT_EXCEEDED,
    FRIEND_NO_TODAY_POST,

    // ── store ──────────────────────────────────────────
    LUNA_INSUFFICIENT,
    STORE_PRODUCT_NOT_FOUND,
    STORE_PRODUCT_INVALID,
    STORE_BOOST_NONE,
    STORE_BOOST_ALREADY_ACTIVE,
    STORE_ALREADY_SUBSCRIBED,
    STORE_NOT_SUBSCRIBED,
    STORE_ALREADY_CANCELED,
    STORE_RECEIPT_INVALID,
    STORE_PURCHASE_FAILED,

    // ── moderation ─────────────────────────────────────
    MODERATION_SELF,
    TARGET_BLOCKED_OR_REPORTED,

    // ── 최후 폴백 ───────────────────────────────────────
    CHAT_VOICE_KEY_REQUIRED,
    CHAT_VOICE_KEY_INVALID,
    CHAT_VOICE_TOO_LONG,
    VALIDATION_FAILED,
    NOT_FOUND,
    INTERNAL_ERROR
}
