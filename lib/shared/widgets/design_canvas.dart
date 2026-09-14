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

  /// 🇯🇵 **일본어판이 실제로 들어와 있는 그림들** — 원문 경로 → 일본어판 규격.
  ///
  /// 여기 적힌 것만 언어에 따라 경로가 바뀐다. 적혀 있지 않으면 **원문(한국어) 그대로** 나간다 —
  /// 일본어판이 없는데 `ja/` 경로를 만들면 **일본어 사용자에게만 그림이 깨지고**,
  /// 한국어로 테스트하는 우리는 영영 모른다(함정 #40과 같은 조용한 죽음).
  /// 한국어가 잠시 보이는 편이 깨진 자리보다 낫다.
  ///
  /// 🚨 **값(규격)이 `null`이 아닌 것은 일본어판 크기가 원문과 다르다는 뜻이다.**
  /// 하단 주메뉴 글자가 그렇다 — 「月光ガーデン」이 `달빛가든`보다 훨씬 넓다(146 → 232).
  /// 원문 규격으로 그리면 **일본어에서만 글자가 눌린다.** 그래서 규격도 함께 적고,
  /// [ArtImage]가 언어에 맞는 크기로 그린다.
  /// (`null`이면 두 판의 규격이 같다는 뜻이고, 테스트가 실제로 같은지 확인한다)
  ///
  /// 📌 **이 목록이 곧 "받은 것"의 기록이다.** 일본어판 파일이 오면
  /// `ja/`에 넣고 여기 한 줄 더하면 끝이다(호출부는 손대지 않는다).
  /// **아직 못 받은 목록**은 `docs/08` §0-1에 있다.
  ///
  /// ⚠️ 새 `ja/` 폴더를 만들었으면 **`pubspec.yaml`에도 줄을 넣을 것**(폴더 선언은 재귀가 아니다).
  /// `test/localized_assets_test.dart`가 파일·선언·규격을 함께 검사한다.
  static const Map<String, Size?> localizedAssets = {
    // 포스트 — 사진을 안 올렸을 때의 안내가 그림에 구워져 있다.
    'assets/images/scene_post/back_nopost.png': null,

    // 하단 주메뉴 글자 — 일본어는 길이가 제각각이라 규격을 따로 적는다.
    'assets/images/scene_garden/menu_post_text_color.png': Size(79, 40),
    'assets/images/scene_garden/menu_post_text_normal.png': Size(79, 40),
    'assets/images/scene_garden/menu_garden_text_color.png': Size(232, 40),
    'assets/images/scene_garden/menu_garden_text_normal.png': Size(237, 40),
    'assets/images/scene_garden/menu_room_text_color.png': Size(155, 36),
    'assets/images/scene_garden/menu_room_text_normal.png': Size(155, 36),
    'assets/images/scene_garden/menu_friend_text_color.png': Size(80, 39),
    'assets/images/scene_garden/menu_friend_text_normal.png': Size(80, 39),
    'assets/images/scene_garden/menu_profile_text_color.png': Size(234, 38),
    'assets/images/scene_garden/menu_profile_text_normal.png': Size(234, 38),
  };

  /// [koAsset]을 [languageCode]로 그릴 때의 **규격**. 일본어판 크기가 따로 적혀 있으면 그것을 쓴다.
  ///
  /// 🚨 이게 없으면 일본어 글자가 **원문 상자에 눌려 들어간다**(「月光ガーデン」이 `달빛가든` 폭으로).
  static Size localizedSize(String koAsset, String languageCode, Size koSize) {
    if (languageCode != 'ja') return koSize;
    return localizedAssets[koAsset] ?? koSize;
  }

  /// **언어별로 다른 그림**을 고른다. (이 앱 UI 언어의 두 번째 종류)
  ///
  /// 글자가 구워진 그림은 ARB로 못 바꾸므로 **언어마다 다른 파일**을 받는다.
  /// 원문(한국어)은 원래 자리에, 일본어판은 **같은 파일명으로 `ja/` 하위 폴더**에 둔다:
  ///
  /// ```
  /// assets/images/scene_post/back_nopost.png      ← 한국어(기본)
  /// assets/images/scene_post/ja/back_nopost.png   ← 일본어
  /// ```
  ///
  /// 📌 **글자가 든 그림은 예외 없이 이걸 거쳐 부르면 된다.** [localizedAssets]에 없으면
  /// 원문을 그대로 돌려주므로, 일본어판이 오기 전에 미리 감싸 두어도 안전하다.
  /// ([ArtImage]는 이미 자동으로 거친다 — 따로 부를 필요가 없다)
  static String localizedAsset(BuildContext context, String koAsset) =>
      localizedAssetFor(koAsset, Localizations.localeOf(context).languageCode);

  /// [localizedAsset]의 알맹이. `BuildContext` 없이 테스트하려고 분리했다.
  ///
  /// 두 번 적용해도 같은 결과다 — `ja/` 경로는 [localizedAssets]에 없으므로 그대로 나간다.
  static String localizedAssetFor(String koAsset, String languageCode) {
    if (languageCode != 'ja') return koAsset;
    if (!localizedAssets.containsKey(koAsset)) return koAsset;

    return japanesePathOf(koAsset);
  }

  /// [koAsset]의 일본어판이 놓일 자리. 목록·테스트가 쓴다.
  static String japanesePathOf(String koAsset) {
    final cut = koAsset.lastIndexOf('/');
    return '${koAsset.substring(0, cut)}/ja${koAsset.substring(cut)}';
  }
}

/// 시안 원본 크기를 적어 두고 화면 폭에 맞춰 줄여 그리는 이미지.
///
/// 크기를 하드코딩하지 않고 **원본 값을 그대로 쓰는** 이유는 나중에
/// **일본어판 이미지로 교체**할 때 같은 규격이면 코드를 손대지 않아도 되기 때문이다.
///
/// 🇯🇵 **언어별 그림을 자동으로 고른다.** 그리기 직전에
/// [DesignCanvas.localizedAsset]을 거치므로 호출부는 원문 경로만 알면 된다 —
/// 일본어판이 들어오면 [DesignCanvas.localizedAssets]에 한 줄 더하는 것으로
/// **이 위젯을 쓰는 모든 자리가 한꺼번에** 일본어로 바뀐다.
/// (글자 없는 그림은 목록에 없으니 아무 일도 일어나지 않는다)
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
    final lang = Localizations.localeOf(context).languageCode;
    // 언어별 그림은 **규격도 언어를 따른다** — 일본어 글자가 원문 상자에 눌리면 안 된다.
    final size = DesignCanvas.localizedSize(asset, lang, Size(width, height));
    final image = Image.asset(
      DesignCanvas.localizedAssetFor(asset, lang),
      width: size.width * s,
      height: size.height * s,
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
