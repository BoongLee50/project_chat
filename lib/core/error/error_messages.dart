import '../../l10n/app_localizations.dart';
import 'api_exception.dart';

/// 오류 코드 → 화면 문구. 번역 자원을 한곳에 모으기 위한 유일한 변환 지점이다.
/// (docs/09 ②단계 — 서버는 코드만 주고 문구는 클라 ARB가 정한다)
///
/// 프로바이더에는 `BuildContext`가 없어 `L10n.of(context)`를 쓸 수 없다(함정 #24).
/// 그래서 프로바이더는 [ApiException]을 그대로 넘기고, `l10n`을 이미 들고 있는
/// 화면이 이 함수로 문장을 만든다.
///
/// 매핑하지 않은 코드는 서버가 준 [ApiException.message]로 폴백한다 —
/// 덕분에 서버에 코드가 새로 생겨도 앱이 깨지지 않는다.
String errorMessage(L10n l10n, ApiException e) {
  return switch (e.code) {
    // ── 공통 ──────────────────────────────────────────
    'USER_NOT_FOUND' => l10n.errorUserNotFound,
    'UNAUTHORIZED' => l10n.errorUnknown,

    // ── auth / profile ───────────────────────────────
    'PROVIDER_DISABLED' => l10n.errorProviderDisabled,
    'NICKNAME_INVALID' => l10n.errorNicknameInvalid,
    'NICKNAME_DUPLICATE' => l10n.errorNicknameDuplicate,
    'NICKNAME_FORMAT' => l10n.errorNicknameFormat,
    'AGE_RESTRICTED' => l10n.errorAgeRestricted,

    // ── post ─────────────────────────────────────────
    'POST_GATE_CLOSED' => l10n.errorPostGateClosed,
    'POST_UPLOAD_WINDOW_CLOSED' => l10n.errorPostUploadWindowClosed,
    'POST_ONELINER_REQUIRED' => l10n.errorPostOneLinerRequired,
    'POST_PHOTO_REQUIRED' => l10n.errorPostPhotoRequired,
    'POST_PHOTO_NOT_FOUND' => l10n.errorPostPhotoNotFound,
    'POST_PHOTO_NOT_MINE' => l10n.errorPostPhotoNotMine,
    'POST_PHOTO_LIMIT' => l10n.errorPostPhotoLimit,
    'POST_REPLACE_LIMIT' => l10n.errorPostReplaceLimit,
    'POST_REPLACE_FREE_LIMIT' => l10n.errorPostReplaceFreeLimit,
    'POST_NOT_PUBLISHED_TODAY' => l10n.errorPostNotPublishedToday,

    // ── garden ───────────────────────────────────────
    'GARDEN_GATE_CLOSED' => l10n.errorGardenGateClosed,
    'GARDEN_TARGET_BLOCKED' => l10n.errorGardenTargetBlocked,

    // ── translate ────────────────────────────────────
    'TRANSLATE_QUOTA_EXCEEDED' => l10n.errorTranslateQuotaExceeded,
    'TRANSLATE_TARGET_REQUIRED' => l10n.errorTranslateTargetRequired,

    // ── chat ─────────────────────────────────────────
    'CHAT_GATE_CLOSED' => l10n.errorChatGateClosed,
    'CHAT_SELF' => l10n.errorChatSelf,
    'CHAT_TARGET_BLOCKED' => l10n.errorChatTargetBlocked,
    'CHAT_REQUEST_PENDING' => l10n.errorChatRequestPending,
    'CHAT_REQUEST_NOT_FOUND' => l10n.errorChatRequestNotFound,
    'CHAT_REQUEST_ALREADY_HANDLED' => l10n.errorChatRequestAlreadyHandled,
    'CHAT_ACCEPT_NOT_RECEIVER' => l10n.errorChatAcceptNotReceiver,
    'CHAT_REJECT_NOT_RECEIVER' => l10n.errorChatRejectNotReceiver,
    'ROOM_ALREADY_ACTIVE' => l10n.errorRoomAlreadyActive,
    'CHAT_ROOM_NOT_FOUND' => l10n.errorChatRoomNotFound,
    'CHAT_ROOM_CLOSED' => l10n.errorChatRoomClosed,
    'CHAT_NOT_MEMBER' => l10n.errorChatNotMember,

    // ── friend ───────────────────────────────────────
    'FRIEND_SELF' => l10n.errorFriendSelf,
    'FRIEND_TARGET_BLOCKED' => l10n.errorFriendTargetBlocked,
    'FRIEND_ALREADY' => l10n.errorFriendAlready,
    'FRIEND_NOT_YET' => l10n.errorFriendNotYet,
    'FRIEND_NOT_MINE' => l10n.errorFriendNotMine,
    'FRIEND_REQUEST_PENDING' => l10n.errorFriendRequestPending,
    'FRIEND_REQUEST_ALREADY_ACCEPTED' => l10n.errorFriendRequestAlreadyAccepted,
    'FRIEND_REQUEST_NOT_FOUND' => l10n.errorFriendRequestNotFound,
    'FRIEND_ACCEPT_NOT_RECEIVER' => l10n.errorFriendAcceptNotReceiver,
    'FRIEND_REJECT_NOT_RECEIVER' => l10n.errorFriendRejectNotReceiver,
    'FRIEND_CANCEL_NOT_SENDER' => l10n.errorFriendCancelNotSender,
    // 한도 숫자는 서버가 field에 실어 보낸다 — 문장 조립은 ARB가 한다.
    'FRIEND_LIMIT_EXCEEDED' => l10n.errorFriendLimitExceeded(
      int.tryParse(e.field ?? '') ?? 0,
    ),
    'FRIEND_NO_TODAY_POST' => l10n.errorFriendNoTodayPost,

    // ── store ────────────────────────────────────────
    'LUNA_INSUFFICIENT' => l10n.errorLunaInsufficient,
    'STORE_PRODUCT_NOT_FOUND' => l10n.errorStoreProductNotFound,
    'STORE_PRODUCT_INVALID' => l10n.errorStoreProductInvalid,
    'STORE_BOOST_NONE' => l10n.errorStoreBoostNone,
    'STORE_BOOST_ALREADY_ACTIVE' => l10n.errorStoreBoostAlreadyActive,
    'STORE_ALREADY_SUBSCRIBED' => l10n.errorStoreAlreadySubscribed,
    'STORE_NOT_SUBSCRIBED' => l10n.errorStoreNotSubscribed,
    'STORE_ALREADY_CANCELED' => l10n.errorStoreAlreadyCanceled,
    'STORE_RECEIPT_INVALID' => l10n.errorStoreReceiptInvalid,
    'STORE_PURCHASE_FAILED' => l10n.errorStorePurchaseFailed,

    // ── moderation ───────────────────────────────────
    'MODERATION_SELF' => l10n.errorModerationSelf,
    'TARGET_BLOCKED_OR_REPORTED' => l10n.errorTargetBlockedOrReported,

    // ── 클라 전용(서버 응답을 못 받은 경우) ──────────────
    ClientErrorCode.networkTimeout => l10n.errorNetworkTimeout,
    ClientErrorCode.networkUnreachable => l10n.errorNetworkUnreachable,
    ClientErrorCode.networkUnknown => l10n.errorNetworkUnknown,
    ClientErrorCode.socketDisconnected => l10n.errorSocketDisconnected,
    ClientErrorCode.socketSendTimeout => l10n.errorSocketSendTimeout,

    // 아직 매핑하지 않은 코드는 서버 문장 그대로. 코드조차 없으면 일반 문구.
    _ => e.code == null ? l10n.errorUnknown : e.message,
  };
}
