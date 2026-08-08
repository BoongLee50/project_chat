/// 레이아웃 치수 토큰 — 간격 / 라운드 / 컴포넌트 크기.
/// 화면 코드에서 하드코딩 대신 이 값을 사용한다.
class AppDimens {
  const AppDimens._();

  // 간격
  static const double gapXs = 4;
  static const double gapSm = 8;
  static const double gapMd = 16;
  static const double gapLg = 24;
  static const double gapXl = 32;

  // 라운드 코너
  static const double radiusMd = 16;
  static const double radiusLg = 20;

  // 컴포넌트
  static const double buttonHeight = 56;
  static const double pagePad = 24;

  /// 하단 5탭 바의 좌우 여백.
  ///
  /// 화면 콘텐츠를 내비와 **같은 폭으로 맞출 때** 이 값을 쓴다(시안에서 달빛가든
  /// 카드와 내비가 같은 선에 놓인다). 한쪽만 바꾸면 어긋나므로 토큰으로 묶어 둔다.
  static const double navSidePad = 12;
}
