/// 서버/네트워크 오류를 화면이 다루기 쉬운 형태로 감싼 예외.
///
/// 서버 에러 응답 포맷: `{ "code": "STRING_CODE", "message": "...", "field": "optional" }`
/// (docs/01-protocol-api-spec.md 공통 규약)
///
/// 화면에 보여줄 문장은 [message]가 아니라 `errorMessage(l10n, e)`로 만든다.
/// [message]는 서버가 준 한국어 원문이라 폴백·로그용이다. (docs/09 ②단계)
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.field,
  });

  /// 서버가 준 원문 메시지. 아직 매핑하지 않은 코드의 폴백으로만 화면에 나간다.
  final String message;

  /// 오류 코드. 문구를 고르는 기준값이다.
  /// 서버 `ErrorCode` 값이거나, 응답조차 못 받은 경우 클라 전용 `NETWORK_*`.
  final String? code;

  /// HTTP 상태 코드(있을 때).
  final int? statusCode;

  /// 코드만으로 부족한 값을 서버가 실어 보내는 자리.
  /// 예) `FRIEND_LIMIT_EXCEEDED`의 한도 숫자 — 클라가 placeholder로 조립한다.
  final String? field;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// 서버 응답을 받지 못한 경우에 쓰는 클라 전용 코드.
/// 서버 `ErrorCode`와 섞이지 않도록 `NETWORK_` 접두사를 붙였다.
class ClientErrorCode {
  const ClientErrorCode._();

  static const String networkTimeout = 'NETWORK_TIMEOUT';
  static const String networkUnreachable = 'NETWORK_UNREACHABLE';
  static const String networkUnknown = 'NETWORK_UNKNOWN';

  /// 소켓이 끊긴 채로 전송을 시도한 경우(REST가 아니라 WebSocket 경로).
  static const String socketDisconnected = 'SOCKET_DISCONNECTED';

  /// 소켓으로 보냈지만 서버 ACK가 오지 않은 경우.
  static const String socketSendTimeout = 'SOCKET_SEND_TIMEOUT';
}
