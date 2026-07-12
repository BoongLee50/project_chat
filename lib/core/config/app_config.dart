/// 앱 전역 상수 / 운영 정책 값.
///
/// 시간 판정의 최종 권위는 서버(KST)에 있다. 아래 시각 값은
/// UI 힌트/폴백 용도일 뿐, 실제 게이트 개폐는 서버 응답을 신뢰한다.
/// (docs/01-protocol-api-spec.md, docs/02-db-schema.md 참고)
class AppConfig {
  const AppConfig._();

  /// 서비스 오픈 시각 (KST, 시)
  static const int openHourKst = 18;

  /// 서비스 종료 시각 (KST, 시)
  static const int closeHourKst = 5;

  /// 포스트/스코어 초기화 시각 (KST, 시)
  static const int postResetHourKst = 6;

  /// API base URL — 서버 스택 확정 후 빌드 환경변수로 주입.
  /// 예: flutter run --dart-define=API_BASE_URL=https://api.example.com
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
}
