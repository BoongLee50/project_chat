/// 앱 전역 상수 / 운영 정책 값.
///
/// 시간 판정의 최종 권위는 서버(KST)에 있다. 아래 시각 값은
/// UI 힌트/폴백 용도일 뿐, 실제 게이트 개폐는 서버 응답을 신뢰한다.
/// (docs/01-protocol-api-spec.md, docs/02-db-schema.md 참고)
class AppConfig {
  const AppConfig._();

  /// 서비스 오픈 시각 (KST, 시) — Plan_2: 오후 5시
  static const int openHourKst = 17;

  /// 서비스 종료 시각 (KST, 시) — Plan_2: 새벽 6시
  static const int closeHourKst = 6;

  /// 포스트/스코어 초기화 시각 (KST, 시) — 새벽 6시 (하루 한마디는 유지)
  static const int postResetHourKst = 6;

  /// API base URL — 빌드 환경변수로 주입.
  /// 예: flutter run --dart-define=API_BASE_URL=https://api.example.com
  ///
  /// 기본값은 **안드로이드 에뮬레이터에서 호스트 PC를 가리키는 주소**(10.0.2.2).
  /// 에뮬레이터의 localhost는 에뮬레이터 자신이라 호스트의 로컬 서버에 닿지 않는다.
  /// (실기기에서 테스트할 땐 PC의 LAN IP를 --dart-define으로 주입)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// 개발용 목 로그인 사용 여부(서버 local 프로필의 mock provider와 짝).
  /// 실제 소셜 SDK 연동 전까지 로그인 흐름을 테스트하기 위한 임시 스위치.
  static const bool useMockLogin = bool.fromEnvironment(
    'USE_MOCK_LOGIN',
    defaultValue: true,
  );
}
