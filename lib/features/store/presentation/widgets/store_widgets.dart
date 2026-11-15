import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/store_models.dart';

/// 상점(`Scene_Shop`) 화면들이 함께 쓰는 조각.
///
/// 좌표는 시안 `*좌표값.png`의 1080 캔버스 숫자 그대로다. 화면은 [ShopCanvas], 팝업은 [ShopPopup]이
/// 한꺼번에 줄여 그린다 — 그래서 여기 숫자는 전부 시안 픽셀이다.
/// (프라임 화면은 아래 버튼·안내가 바닥에 붙는 다른 모양이라 `prime_screen.dart`가 따로 갖는다)

const shopDir = 'assets/images/scene_shop';

/// 상품 구매·관리·구매 완료 그림(`Scene_Shop(New)`, 2026-11-14) — 폴더마다 같은 그림이 겹쳐 와서 한 벌로 모았다.
const itemDir = '$shopDir/item';

/// 시안에서 뽑은 색(참고화면 픽셀).
abstract final class ShopColors {
  static const name = Color(0xFF1C1F24); // 목록 `포스트 부스트 5개` · 한 줄
  static const purple = Color(0xFF2702FB); // 목록 이름의 숫자 · 관리 칸 숫자
  static const yellow = Color(0xFFFFC21C); // 관리 `15개`의 숫자
  static const lavender = Color(0xFFE3D1FC); // 보라 틀 안 혜택 설명
  static const head = Color(0xFFE9EAEC); // 보라 바탕 위 머리글(`사용 정보` 등)
  static const soft = Color(0xFF606470); // 흰 팝업 혜택 설명
  static const red = Color(0xFFFB0B44); // `20%`(할인 표시 그림의 흰 칸)
}

/// 시안 y → 화면에 놓을 y. 세로가 모자란 기기에서 빈 띠를 줄인 만큼 당겨 준다.
typedef ShopY = double Function(double designY);

/// 시안 캔버스(1080 폭)를 그대로 그리고 화면에 맞춘다. **스크롤하지 않는다**(고정 화면).
///
/// 시안은 1080×2640(약 2.44:1)인데 흔한 폰은 20:9(2.22:1)라 세로가 모자란다. 모자라면
/// ① 타이틀 위(상태바 바로 아래까지) ② [gaps]에 적은 틈들을 차례로 줄이고(각자 한도까지)
/// ③ 그래도 모자랄 때만 **전체를 같은 비율로 줄인다**(좌우에 여백이 생긴다).
/// 위치는 [children]이 받는 `y()`로 이 몫을 반영한다. [background]는 줄이지 않고 화면 전체에 깐다.
class ShopCanvas extends StatelessWidget {
  const ShopCanvas({
    super.key,
    required this.contentBottom,
    required this.children,
    this.gaps = const [],
    this.topmost = 107,
    this.background,
  });

  /// 가장 아래 있는 것의 아랫변(시안 y).
  final double contentBottom;

  /// 줄여도 되는 틈 — (이 y부터 아래가 당겨진다, 최대 몇 px).
  final List<(double, double)> gaps;

  /// 가장 위에 있는 것의 윗변(타이틀 아이콘 107).
  final double topmost;

  /// 화면 전체 배경 그림(1080×2640) — 세로가 모자라면 아래가 잘린다.
  final String? background;

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

        return Stack(
          children: [
            if (background != null)
              Positioned.fill(
                child: Image.asset(
                  background!,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            MediaQuery.withNoTextScaling(
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: DesignCanvas.width,
                  height: h + short,
                  child: Stack(children: children(y)),
                ),
              ),
            ),
          ],
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

/// 시안 좌표에 글 한 줄(윗변 = 시안 좌표값의 y — 글꼴 위 여백만큼 살짝 올린다).
Widget shopText(
  String text,
  double left,
  double top,
  TextStyle style, {
  double? width,
  TextAlign align = TextAlign.start,
}) => Positioned(
  left: left,
  top: top - style.fontSize! * 0.12,
  width: width,
  child: Text(text, textAlign: align, style: style),
);

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
  });

  final String frame;
  final Size size;
  final Offset origin;

  /// (시안 x, 시안 y) → 틀 안 위치로 바꿔 주는 함수를 받아 아이들을 만든다.
  final List<Widget> Function(double Function(double) x, double Function(double) y)
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
                    ArtImage(frame, width: size.width, height: size.height, scale: 1),
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

/// 혜택 줄 틀 — 체크 · 굵은 제목 · 두 줄 설명. 틀 그림은 호출부가 깔고 이건 **글만** 세로 가운데에 둔다.
///
/// 보라 틀(구매·관리 화면)은 흰 체크·흰 제목·연보라 설명, 흰 팝업은 검은 체크·검은 제목·회색 설명이다.
/// 시안: 체크는 틀 왼쪽에서 약 40, 제목은 약 130.
class ShopBenefitList extends StatelessWidget {
  const ShopBenefitList({
    super.key,
    required this.size,
    required this.items,
    this.onPurple = true,
    this.gap = 34,
  });

  final Size size;
  final List<(String, String)> items;
  final bool onPurple;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final title = onPurple ? Colors.white : Colors.black;
    final desc = onPurple ? ShopColors.lavender : ShopColors.soft;
    final check = onPurple ? '$itemDir/icon_wcheck.png' : '$shopDir/prime_sub/sub_start/icon_primecheck.png';
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 24, 20, 24),
        // 일본어처럼 줄이 늘어도 틀 밖으로 나가지 않게 — 넘치면 통째로 조금 줄인다.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: size.width - 40 - 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) SizedBox(height: gap),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: ArtImage(check, width: 56, height: 45, scale: 1),
                      ),
                      const SizedBox(width: 130 - 40 - 56),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].$1,
                              style: TextStyle(
                                color: title,
                                fontSize: 47,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              items[i].$2,
                              style: TextStyle(
                                color: desc,
                                fontSize: 36,
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
    );
  }
}

/// 상품 종류별 그림·문구 — 구매 화면 · 관리 화면 · 구매 완료 팝업이 같은 표를 본다.
class ShopKind {
  const ShopKind._(this.kind);

  final String kind;

  static const boost = ShopKind._(StoreKind.postBoost);
  static const album = ShopKind._(StoreKind.albumPass);
  static const trans = ShopKind._(StoreKind.translatePass);
  static const all = [boost, album, trans];

  static ShopKind? of(String kind) {
    for (final k in all) {
      if (k.kind == kind) return k;
    }
    return null;
  }

  bool get isBoost => kind == StoreKind.postBoost;

  T _pick<T>(T boost, T album, T trans) => switch (kind) {
    StoreKind.postBoost => boost,
    StoreKind.albumPass => album,
    _ => trans,
  };

  /// 타이틀 줄 — 큰 아이콘(시안 좌표)과 이름 그림.
  (String, Size, Offset) get bigIcon => _pick(
    ('$itemDir/icon_postboost_l.png', const Size(119, 117), const Offset(215, 107)),
    ('$itemDir/icon_postalbum_l.png', const Size(104, 96), const Offset(244, 119)),
    ('$itemDir/icon_trans_l.png', const Size(120, 119), const Offset(232, 107)),
  );
  (String, Size, Offset) get title => _pick(
    ('$itemDir/title_boostshop.png', const Size(475, 77), const Offset(366, 129)),
    ('$itemDir/title_albumshop.png', const Size(399, 76), const Offset(386, 131)),
    ('$itemDir/title_transshop.png', const Size(315, 76), const Offset(389, 130)),
  );

  /// 구매 화면 가운데 그림.
  (String, Size, Offset) get hero => _pick(
    ('$itemDir/icon_boost_image.png', const Size(415, 226), const Offset(371, 386)),
    ('$itemDir/icon_album_image.png', const Size(311, 209), const Offset(365, 397)),
    ('$itemDir/icon_trans_image.png', const Size(278, 221), const Offset(390, 389)),
  );

  /// 구매 목록 줄의 작은 아이콘.
  (String, Size) get smallIcon => _pick(
    ('$itemDir/icon_postboost_s.png', const Size(90, 88)),
    ('$itemDir/icon_postalbum_s.png', const Size(87, 80)),
    ('$itemDir/icon_trans_s.png', const Size(89, 88)),
  );

  /// 구매 완료 팝업의 아이콘.
  (String, Size) get popupIcon => _pick(
    ('$itemDir/icon_boost_l.png', const Size(101, 99)),
    ('$itemDir/icon_postalbum_l.png', const Size(104, 96)),
    ('$itemDir/icon_trans.png', const Size(102, 101)),
  );

  /// 구매 화면의 [프라임 멤버십 구독 시 ›] 배너(글자가 구워져 있다).
  String get primeBanner => _pick(
    '$itemDir/button_prime_boost.png',
    '$itemDir/button_prime_album.png',
    '$itemDir/button_prime_trans.png',
  );

  /// 관리 화면 두 칸 — 자동 번역도 앨범과 같은 칸(`구독 기간 적용`·`구매한 이용 기간`)을 쓴다.
  String get primeColumn =>
      isBoost ? '$itemDir/frame_primeboost.png' : '$itemDir/frame_primealbum.png';
  String get storeColumn =>
      isBoost ? '$itemDir/frame_shopboost.png' : '$itemDir/frame_shopalbum.png';

  /// 관리 화면 `보유량`(부스트) · `보유기간`(패스) 그림.
  (String, Size, Offset) get holdingTitle => isBoost
      ? ('$itemDir/title_reserves.png', const Size(265, 91), const Offset(409, 309))
      : ('$itemDir/title_retention.png', const Size(347, 90), const Offset(366, 309));

  String name(L10n l10n) =>
      _pick(l10n.lunaItemBoost, l10n.lunaItemAlbum, l10n.lunaItemTrans);

  /// `포스트 부스트 5개` · `자동 번역 7일`.
  String productName(L10n l10n, ShopProduct p) => p.isBoost
      ? l10n.lunaItemCount(name(l10n), p.quantity)
      : l10n.lunaItemDays(name(l10n), p.durationDays);

  /// 구매 화면 맨 위 설명 두 줄. 앨범 장수는 서버 설정값이다.
  String description(L10n l10n, int maxPhotos) => _pick(
    l10n.shopDescBoost,
    l10n.shopDescAlbum(maxPhotos),
    l10n.shopDescTrans,
  );

  String benefitHead(L10n l10n) => _pick(
    l10n.lunaBenefitHeadBoost,
    l10n.lunaBenefitHeadAlbum,
    l10n.lunaBenefitHeadTrans,
  );

  /// 혜택 세 줄. 앨범 장수는 서버 설정값([ProductCatalog.maxPhotosPass])이다.
  List<(String, String)> benefits(L10n l10n, int maxPhotos) => _pick(
    [
      (l10n.lunaBoostBenefit1, l10n.lunaBoostBenefit1Desc),
      (l10n.lunaBoostBenefit2, l10n.lunaBoostBenefit2Desc),
      (l10n.lunaBoostBenefit3, l10n.lunaBoostBenefit3Desc),
    ],
    [
      (l10n.lunaAlbumBenefit1(maxPhotos), l10n.lunaAlbumBenefit1Desc(maxPhotos)),
      (l10n.lunaAlbumBenefit2, l10n.lunaAlbumBenefit2Desc),
      (l10n.lunaAlbumBenefit3, l10n.lunaAlbumBenefit3Desc),
    ],
    [
      (l10n.lunaTransBenefit1, l10n.lunaTransBenefit1Desc),
      (l10n.lunaTransBenefit2, l10n.lunaTransBenefit2Desc),
      (l10n.lunaTransBenefit3, l10n.lunaTransBenefit3Desc),
    ],
  );
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

/// `2026. 10. 12 14:26` — 관리 화면의 날짜 표기.
String shopDateTime(DateTime? value) {
  if (value == null) return '-';
  final v = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${v.year}. ${two(v.month)}. ${two(v.day)} ${two(v.hour)}:${two(v.minute)}';
}
