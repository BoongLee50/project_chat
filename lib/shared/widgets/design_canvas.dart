import 'package:flutter/material.dart';

/// 기획 시안(1080×2640)을 화면에 그대로 옮기기 위한 좌표 도구. (Plan_4)
///
/// **Plan_4에서 좌표 표기가 바뀌었다.** Plan_3은 `X*Y` 단위 쌍이고 1단위 ≈ 28.4px였는데,
/// Plan_4의 `*_좌표값.png`는 **1080 캔버스의 픽셀값을 그대로** 적는다(예: `47, 106`).
/// 그래서 변환이 없다 — 시안에 적힌 숫자를 그대로 쓰면 된다.
///
/// ⚠️ 같은 폴더의 `*_참고용.png`는 **Plan_3 시절 것**이라 옛 단위 표기다. 헷갈리지 말 것.
///
/// **이 앱의 UI 언어는 두 종류다** — 폰트(ARB)와 **이미지(글자가 구워진 것)**.
/// 여기서 배치하는 그림 속 한글은 결함이 아니라 의도된 상태이고,
/// 일본어판은 **같은 규격의 일본어 이미지**를 따로 받아 교체한다.
class DesignCanvas {
  const DesignCanvas._();

  /// 시안 캔버스 규격. 에셋의 원본 픽셀이 이 크기를 전제로 그려져 있다.
  static const double width = 1080;
  static const double height = 2640;

  /// 본문 좌우 위치 — **하단 주메뉴와 포스트 카드가 같은 폭**이다(시안 확인).
  /// 주메뉴 외곽선이 `23, 2295`에 1031폭, 가든 카드가 `23, 475`에 1032폭으로
  /// 시작하므로 한곳에 두고 양쪽이 같은 값을 쓴다 — 따로 두면 어긋난다.
  static const double contentLeft = 23;
  static const double contentWidth = 1032;

  /// 타이틀 윗변(시안 `47, 106`의 y). **화면 맨 위 기준**이다.
  static const double titleTop = 106;

  /// 카드 윗변(시안 `23, 475`) — **포스트와 달빛가든이 같은 값**이다.
  static const double cardTop = 475;

  /// 머리글 줄의 윗변. **타이틀(106)이 아니라 Prime 버튼(102)이 기준**이다.
  ///
  /// ⚠️ 머리글은 `Row`라 **가장 큰 요소가 줄 높이를 정한다.** 타이틀은 66~71인데
  /// Prime 버튼이 83이라 실제 줄 높이는 83이고, 시작도 그만큼 위(102)다.
  /// 타이틀 높이로 계산하면 두 화면의 카드 시작 위치가 어긋난다(실제로 7px 어긋났다).
  static const double headerTop = 102;
  static const double headerHeight = 83;

  /// 머리글 아랫변(185) → 다음 줄 윗변(356). **두 화면이 같다** —
  /// 포스트는 패스·부스트 두 버튼, 가든은 필터 네 칸이 그 자리에 온다.
  static const double headerToRow = 356 - (headerTop + headerHeight);

  /// 카드 아랫변(시안 2272)과 하단 주메뉴(2295) 사이.
  ///
  /// ⚠️ **두 화면이 반드시 같은 값을 써야 한다.** 예전에 포스트만 시안 값을 쓰고
  /// 달빛가든은 `AppDimens.gapMd`(16 **논리**px)를 써서, 같은 카드인데
  /// **가든 쪽만 19px 짧았다.** 배율이 걸리는 값과 안 걸리는 값을 섞으면 이렇게 갈라진다.
  static const double cardBottomGap = 2295 - 2272;

  /// SafeArea 안에서 쓸 머리글 위 여백.
  ///
  /// ⚠️ 시안의 값은 상태바를 고려하지 않았는데, 실제로 그 높이가 **상태바와 거의 같다**
  /// (완성 화면에서 타이틀이 상태바 바로 아래에 붙어 있다). SafeArea 안에서 그대로
  /// 더하면 **상태바 높이만큼 두 번 밀려** 배경 사진과 아래 버튼 사이가 벌어진다.
  /// 그래서 이미 밀린 만큼을 빼 준다. 상태바가 더 큰 기기에서는 0이 된다.
  static double titleTopInSafeArea(BuildContext context) {
    final statusBar = MediaQueryData.fromView(View.of(context)).padding.top;
    return (headerTop * scaleOf(context) - statusBar)
        .clamp(0.0, double.infinity);
  }

  /// 카드 위에 쌓인 것들의 높이 — **두 화면이 이 함수를 함께 쓴다.**
  ///
  /// 값이 갈라지면 같은 카드인데 화면마다 크기가 달라진다(실제로 그렇게 어긋났다).
  ///
  /// [rowHeight]  머리글 아래 한 줄의 높이(포스트 96 · 가든 94)
  /// [rowToCard]  그 줄과 카드 사이(포스트 23 · 가든 25)
  static double aboveCard(
    BuildContext context, {
    required double rowHeight,
    required double rowToCard,
  }) =>
      titleTopInSafeArea(context) +
      (headerHeight + headerToRow + rowHeight + rowToCard) * scaleOf(context);

  /// 화면 폭에 맞춘 배율. 폭이 좁은 기기에서도 시안 비율이 유지된다.
  static double scaleOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width / width;

  /// 시안 픽셀 → 실제 논리픽셀.
  static double px(BuildContext context, double designPx) =>
      designPx * scaleOf(context);

  /// **언어별로 다른 그림**을 고른다. (이 앱 UI 언어의 두 번째 종류)
  ///
  /// 글자가 구워진 그림은 ARB로 못 바꾸므로 **언어마다 다른 파일**을 받는다.
  /// 원문(한국어)은 원래 자리에, 일본어판은 **같은 파일명으로 `ja/` 하위 폴더**에 둔다:
  ///
  /// ```
  /// assets/images/post/empty_bg.png      ← 한국어(기본)
  /// assets/images/post/ja/empty_bg.png   ← 일본어
  /// ```
  ///
  /// ⚠️ **두 벌이 다 있는 그림에만 쓸 것.** 없는 쪽을 부르면 런타임에 에셋을 못 찾는다.
  /// 폴더를 새로 만들면 `pubspec.yaml`에도 줄을 넣어야 한다(함정 #30).
  static String localizedAsset(BuildContext context, String koAsset) {
    if (Localizations.localeOf(context).languageCode != 'ja') return koAsset;
    final cut = koAsset.lastIndexOf('/');
    return '${koAsset.substring(0, cut)}/ja${koAsset.substring(cut)}';
  }
}

/// 시안 원본 크기를 적어 두고 화면 폭에 맞춰 줄여 그리는 이미지.
///
/// 크기를 하드코딩하지 않고 **원본 값을 그대로 쓰는** 이유는 나중에
/// **일본어판 이미지로 교체**할 때 같은 규격이면 코드를 손대지 않아도 되기 때문이다.
class ArtImage extends StatelessWidget {
  const ArtImage(
    this.asset, {
    required this.width,
    required this.height,
    this.scale,
    this.opacity = 1.0,
    this.fit = BoxFit.contain,
    super.key,
  });

  /// 시안 원본 픽셀(1080 캔버스 기준).
  final double width;
  final double height;
  final String asset;

  /// 배율을 직접 줄 때 사용. 없으면 화면 폭 기준([DesignCanvas.scaleOf]).
  final double? scale;

  final double opacity;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final s = scale ?? DesignCanvas.scaleOf(context);
    final image = Image.asset(
      asset,
      width: width * s,
      height: height * s,
      fit: fit,
      filterQuality: FilterQuality.medium,
    );
    return opacity == 1.0 ? image : Opacity(opacity: opacity, child: image);
  }
}

/// 시안 좌표에 그대로 얹는 배치기.
///
/// 시안이 좌상단 기준 절대 좌표를 주므로 `Stack` + `Positioned`가 가장 정직하다.
/// 다만 **화면 높이는 기기마다 다르다** — 세로 좌표를 그대로 쓰면 긴 화면에서 뜬다.
/// 그래서 세로는 이 위젯을 쓰지 않고 [Column]으로 쌓되, 간격만 시안 값을 참고한다.
/// (가로 위치·크기는 폭 배율이 정확해 그대로 써도 어긋나지 않는다)
class DesignPositioned extends StatelessWidget {
  const DesignPositioned({
    super.key,
    required this.left,
    required this.top,
    required this.child,
  });

  final double left;
  final double top;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    return Positioned(left: left * s, top: top * s, child: child);
  }
}
