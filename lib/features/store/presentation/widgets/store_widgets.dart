import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/store_models.dart';

/// 상점(`Scene_Shop`) 화면들이 함께 쓰는 조각.
///
/// 시안은 **밝은 바탕**이고 좌표는 `*좌표값.png`의 1080 캔버스 숫자 그대로다.
/// 화면은 [ShopCanvas], 팝업은 [ShopPopup]이 한꺼번에 줄여 그린다 — 그래서 여기 숫자는 전부 시안 픽셀이다.
/// (프라임 화면은 아래 버튼·안내가 바닥에 붙는 다른 모양이라 `prime_screen.dart`가 따로 갖는다)

const shopDir = 'assets/images/scene_shop';

/// 시안에서 뽑은 색(참고화면 픽셀).
abstract final class ShopColors {
  static const ink = Color(0xFF1E1E1D); // 카드 설명 · 본문
  static const sub = Color(0xFF5E5D5D); // 타이틀 밑 한 줄
  static const soft = Color(0xFF606470); // 혜택 설명
  static const tag = Color(0xFF3A3939); // 충전 카드 한 줄
  static const purple = Color(0xFF3C03FA); // `루나 100개`의 숫자
  static const red = Color(0xFFFB0B44); // 충전 카드 `20%`
}

/// 시안 y → 화면에 놓을 y. 세로가 모자란 기기에서 빈 띠를 줄인 만큼 당겨 준다.
typedef ShopY = double Function(double designY);

/// 시안 캔버스(1080 폭)를 그대로 그리고 화면에 맞춘다. **스크롤하지 않는다**(고정 화면).
///
/// 시안은 1080×2640(약 2.44:1)인데 흔한 폰은 20:9(2.22:1)라 세로가 모자란다. 모자라면
/// ① 타이틀 위(상태바 바로 아래까지) ② [gaps]에 적은 틈들을 차례로 줄이고(각자 한도까지)
/// ③ 그래도 모자랄 때만 **전체를 같은 비율로 줄인다**(좌우에 여백이 생긴다).
/// 위치는 [children]이 받는 `y()`로 이 몫을 반영한다.
class ShopCanvas extends StatelessWidget {
  const ShopCanvas({
    super.key,
    required this.contentBottom,
    required this.children,
    this.gaps = const [],
    this.topmost = 133,
  });

  /// 가장 아래 있는 것의 아랫변(시안 y).
  final double contentBottom;

  /// 줄여도 되는 틈 — (이 y부터 아래가 당겨진다, 최대 몇 px).
  final List<(double, double)> gaps;

  /// 가장 위에 있는 것의 윗변(보통 [X]의 133).
  final double topmost;

  final List<Widget> Function(ShopY y) children;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final s = c.maxWidth / DesignCanvas.width;
        final h = c.maxHeight / s;
        final statusBar = mq.padding.top / s;
        final nav = mq.padding.bottom / s;

        var short = math.max(0.0, contentBottom + nav + 24 - h);
        final shift = math.min(short, math.max(0.0, topmost - statusBar - 16));
        short -= shift;
        final cuts = <double>[];
        for (var i = 0; i < gaps.length; i++) {
          final cut = math.min(gaps[i].$2, short / (gaps.length - i));
          cuts.add(cut);
          short -= cut;
        }
        double y(double v) {
          var out = v - shift;
          for (var i = 0; i < gaps.length; i++) {
            if (v >= gaps[i].$1) out -= cuts[i];
          }
          return out;
        }

        return MediaQuery.withNoTextScaling(
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: DesignCanvas.width,
              height: h + short,
              child: Stack(children: children(y)),
            ),
          ),
        );
      },
    );
  }
}

/// 시안 좌표에 그림 한 장.
Widget shopArt(String asset, double left, double top, double w, double h) =>
    Positioned(
      left: left,
      top: top,
      child: ArtImage(asset, width: w, height: h, scale: 1),
    );

/// 오른쪽 위 [X] — 상점 화면 셋이 같은 그림·같은 자리(928, 133)다.
Widget shopClose(BuildContext context, double top) => Positioned(
  left: 928 - 20,
  top: top - 20,
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => Navigator.of(context).maybePop(),
    child: const Padding(
      padding: EdgeInsets.all(20), // 손가락 자리 — 그림(94)보다 넓게
      child: ArtImage(
        '$shopDir/luna_shop/button_primeexit.png',
        width: 94,
        height: 94,
        scale: 1,
      ),
    ),
  ),
);

/// 타이틀 밑 한 줄(가운데).
Widget shopSubtitle(String text, double top) => Positioned(
  left: 40,
  right: 40,
  top: top - 4,
  child: Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: ShopColors.sub,
      fontSize: 36,
      fontWeight: FontWeight.w500,
      height: 1,
    ),
  ),
);

/// 보유량 배너(49, 349) — 보라 알약 안에 숫자, 오른쪽에 버튼 하나(상점은 [루나 충전하기], 충전은 [루나 상점가기]).
List<Widget> shopBalance({
  required String banner,
  required int luna,
  required String button,
  required Size buttonSize,
  required Offset buttonAt,
  required VoidCallback onTap,
  required ShopY y,
}) => [
  shopArt(banner, 49, y(349), 986, 185),
  // 알약(그림 안 252~529) 별 오른쪽 칸 가운데.
  Positioned(
    left: 49 + 335,
    width: 529 - 335,
    top: y(349) + 53,
    height: 130 - 53,
    child: Center(
      child: Text(
        shopNumber(luna),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 58,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    ),
  ),
  Positioned(
    left: buttonAt.dx,
    top: y(buttonAt.dy),
    child: ShopArtButton(
      asset: button,
      width: buttonSize.width,
      height: buttonSize.height,
      onTap: onTap,
    ),
  ),
];

/// 글자가 구워진 그림 버튼. 금액처럼 변하는 값은 [overlay]로 얹는다.
class ShopArtButton extends StatelessWidget {
  const ShopArtButton({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
    required this.onTap,
    this.overlay,
  });

  final String asset;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            ArtImage(asset, width: width, height: height, scale: 1),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

/// 상점 팝업 — 그림 틀([frame], 982폭)을 화면 가운데 그리고, 안은 **시안 화면 좌표**로 놓는다.
///
/// 시안 좌표는 화면 기준이라 틀의 왼쪽 위([origin])를 빼서 쓴다 — 호출부는 `*좌표값.png` 숫자를 그대로 적는다.
/// 틀이 화면보다 길면(짧은 폰) 높이에 맞춰 줄인다.
class ShopPopup extends StatelessWidget {
  const ShopPopup({
    super.key,
    required this.frame,
    required this.size,
    required this.origin,
    required this.children,
    this.frameSize,
  });

  final String frame;
  final Size size;
  final Offset origin;

  /// 틀 그림의 실제 크기가 시안 틀([size])과 다를 때. 둥근 모서리는 그대로 두고 **가운데만 늘린다**.
  /// (구매 완료 틀 `frame_lunapopup`은 1650인데 시안 틀은 1816이라 [나가기]가 틀 밖으로 나갔다)
  final Size? frameSize;

  /// (시안 x, 시안 y) → 틀 안 위치로 바꿔 주는 함수를 받아 아이들을 만든다.
  final List<Widget> Function(
    double Function(double) x,
    double Function(double) y,
  )
  children;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final byWidth = mq.size.width / DesignCanvas.width;
    final byHeight = (mq.size.height - mq.padding.vertical - 24) / size.height;
    final s = math.min(byWidth, byHeight);

    return Center(
      child: MediaQuery.withNoTextScaling(
        child: SizedBox(
          width: size.width * s,
          height: size.height * s,
          child: FittedBox(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Material(
                type: MaterialType.transparency,
                child: Stack(
                  children: [
                    if (frameSize == null)
                      ArtImage(
                        frame,
                        width: size.width,
                        height: size.height,
                        scale: 1,
                      )
                    else
                      Image.asset(
                        frame,
                        width: size.width,
                        height: size.height,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                        // 모서리 120px은 늘리지 않는다(그림 크기 기준).
                        centerSlice: Rect.fromLTWH(
                          120,
                          120,
                          frameSize!.width - 240,
                          frameSize!.height - 240,
                        ),
                      ),
                    ...children((v) => v - origin.dx, (v) => v - origin.dy),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 팝업을 띄운다(어두운 바깥 · 바깥을 누르면 닫힘).
Future<T?> showShopPopup<T>(BuildContext context, WidgetBuilder builder) =>
    showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: builder,
    );

/// 혜택 세 줄 틀(`frame_iteminfo` 903×625) — 체크 · 굵은 제목 · 회색 두 줄. 팝업 둘이 함께 쓴다.
///
/// 시안: 틀 왼쪽 위에서 체크 (43, 58), 제목 (129, 42), 줄 간격 약 200.
class ShopBenefitBox extends StatelessWidget {
  const ShopBenefitBox({super.key, required this.asset, required this.items});

  final String asset;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 903,
      height: 625,
      child: Stack(
        children: [
          ArtImage(asset, width: 903, height: 625, scale: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(43, 34, 20, 30),
            // 일본어처럼 줄이 늘어도 틀 밖으로 나가지 않게 — 넘치면 통째로 조금 줄인다.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 903 - 43 - 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 26),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 22),
                            child: ArtImage(
                              '$shopDir/luna_buy_after/icon_primecheck.png',
                              width: 56,
                              height: 45,
                              scale: 1,
                            ),
                          ),
                          const SizedBox(width: 129 - 43 - 56),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  items[i].$1,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 46,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  items[i].$2,
                                  style: const TextStyle(
                                    color: ShopColors.soft,
                                    fontSize: 35,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 팝업의 `○○ 혜택` 머리(108, …).
Widget shopBenefitHead(String text, double left, double top) => Positioned(
  left: left,
  top: top - 6,
  child: Text(
    text,
    style: const TextStyle(
      color: Colors.black,
      fontSize: 46,
      fontWeight: FontWeight.w500,
      height: 1,
    ),
  ),
);

/// 상품 종류별 그림·문구 — 상점 카드 · 상품 관리 · 구매 완료가 같은 표를 본다.
class ShopKindArt {
  const ShopKindArt._(this.kind);

  final String kind;

  static const boost = ShopKindArt._(StoreKind.postBoost);
  static const album = ShopKindArt._(StoreKind.albumPass);
  static const trans = ShopKindArt._(StoreKind.translatePass);
  static const all = [boost, album, trans];

  static ShopKindArt? of(String kind) {
    for (final k in all) {
      if (k.kind == kind) return k;
    }
    return null;
  }

  bool get isBoost => kind == StoreKind.postBoost;

  String get _short => switch (kind) {
    StoreKind.postBoost => 'boost',
    StoreKind.albumPass => 'album',
    _ => 'trans',
  };

  /// 동그란 아이콘(약 102×100).
  String get icon => '$shopDir/luna_shop/icon_$_short.png';
  Size get iconSize => switch (kind) {
    StoreKind.postBoost => const Size(101, 99),
    StoreKind.albumPass => const Size(102, 99),
    _ => const Size(102, 101),
  };

  /// 상점 카드 왼쪽 아래 그림.
  String get describe => '$shopDir/luna_shop/icon_${_short}_descrbe.png';
  Size get describeSize => switch (kind) {
    StoreKind.postBoost => const Size(385, 187),
    StoreKind.albumPass => const Size(363, 187),
    _ => const Size(319, 186),
  };

  /// 상점 카드 제목(그림 — 글자가 구워져 있다).
  String get title => '$shopDir/luna_shop/title_$_short.png';
  Size get titleSize => switch (kind) {
    StoreKind.postBoost => const Size(429, 53),
    StoreKind.albumPass => const Size(338, 50),
    _ => const Size(207, 52),
  };

  /// 상품 관리 팝업 맨 위 그림.
  String get image => '$shopDir/luna_buy_prev/icon_${_short}_image.png';
  Size get imageSize => switch (kind) {
    StoreKind.postBoost => const Size(365, 162),
    StoreKind.albumPass => const Size(365, 194),
    _ => const Size(330, 194),
  };

  String name(L10n l10n) => switch (kind) {
    StoreKind.postBoost => l10n.lunaItemBoost,
    StoreKind.albumPass => l10n.lunaItemAlbum,
    _ => l10n.lunaItemTrans,
  };

  /// `포스트 부스트 5개` · `자동 번역 7일`.
  String productName(L10n l10n, LunaProduct p) => p.isBoost
      ? l10n.lunaItemCount(name(l10n), p.quantity)
      : l10n.lunaItemDays(name(l10n), p.durationDays);

  String benefitHead(L10n l10n) => switch (kind) {
    StoreKind.postBoost => l10n.lunaBenefitHeadBoost,
    StoreKind.albumPass => l10n.lunaBenefitHeadAlbum,
    _ => l10n.lunaBenefitHeadTrans,
  };

  /// 혜택 세 줄. 앨범 장수는 서버 설정값([ProductCatalog.maxPhotosPass])이다.
  List<(String, String)> benefits(L10n l10n, int maxPhotos) => switch (kind) {
    StoreKind.postBoost => [
      (l10n.lunaBoostBenefit1, l10n.lunaBoostBenefit1Desc),
      (l10n.lunaBoostBenefit2, l10n.lunaBoostBenefit2Desc),
      (l10n.lunaBoostBenefit3, l10n.lunaBoostBenefit3Desc),
    ],
    StoreKind.albumPass => [
      (
        l10n.lunaAlbumBenefit1(maxPhotos),
        l10n.lunaAlbumBenefit1Desc(maxPhotos),
      ),
      (l10n.lunaAlbumBenefit2, l10n.lunaAlbumBenefit2Desc),
      (l10n.lunaAlbumBenefit3, l10n.lunaAlbumBenefit3Desc),
    ],
    _ => [
      (l10n.lunaTransBenefit1, l10n.lunaTransBenefit1Desc),
      (l10n.lunaTransBenefit2, l10n.lunaTransBenefit2Desc),
      (l10n.lunaTransBenefit3, l10n.lunaTransBenefit3Desc),
    ],
  };

  /// 상점 카드 옵션 그림(글자 `5개`·`30일`이 구워져 있다). 그림이 없는 구성은 null.
  String? optionAsset(LunaProduct p, bool on) {
    final base = switch ((p.isBoost, p.isBoost ? p.quantity : p.durationDays)) {
      (true, 5) => '5boost',
      (true, 10) => '10boost',
      (false, 7) => '7day',
      (false, 30) => '30day',
      _ => null,
    };
    return base == null
        ? null
        : '$shopDir/luna_shop/button_$base${on ? 'color' : 'normal'}.png';
  }
}

/// `12,900` — 세 자리마다 쉼표.
String shopNumber(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// `2026. 10. 12 14:26` — 상품 관리 팝업의 날짜 표기.
String shopDateTime(DateTime? value) {
  if (value == null) return '-';
  final v = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${v.year}. ${two(v.month)}. ${two(v.day)} ${two(v.hour)}:${two(v.minute)}';
}
