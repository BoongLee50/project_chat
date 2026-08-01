/// 서버/네트워크 오류를 화면이 다루기 쉬운 형태로 감싼 예외.
///
/// 서버 에러 응답 포맷: `{ "code": "STRING_CODE", "message": "...", "field": "optional" }`
/// (docs/01-protocol-api-spec.md 공통 규약)
class ApiException implements Exception {
  const ApiException({required this.message, this.code, this.statusCode});

  /// 사용자에게 보여줄 수 있는 메시지.
  final String message;

  /// 서버가 준 에러 코드(있을 때). 분기 처리에 사용.
  final String? code;

  /// HTTP 상태 코드(있을 때).
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
