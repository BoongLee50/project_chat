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
/// 덕분에 전 코드를 한 번에 옮기지 않아도 앱이 깨지지 않는다.
String errorMessage(L10n l10n, ApiException e) {
  return switch (e.code) {
    // 도메인별 문구는 3/5 단계에서 채운다. 지금은 배관만 통과시킨다.
    _ => e.message,
  };
}
