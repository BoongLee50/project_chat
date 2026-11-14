import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import 'store_widgets.dart';

/// 상품 구매 완료 팝업(시안 `상품별 구매 확인 팝업/{포스트 부스트·포스트 앨범·자동 번역} 구매 확인`).
/// [보유 상품 확인] → true(관리 화면으로), [나가기]·바깥 → false.
Future<bool?> showItemPurchasedPopup(BuildContext context, ShopProduct product) =>
    showShopPopup<bool>(context, (_) => _ItemPurchased(product: product));

/// 프라임 구매 완료 팝업(시안 `프라임 구독 구매 확인`). [보유 상품 확인] → true.
Future<bool?> showPrimePurchasedPopup(BuildContext context, PrimePlan plan) =>
    showShopPopup<bool>(context, (_) => _PrimePurchased(plan: plan));

/// 부스트 사용 확인(기획서 261111 10-2 — "포스트 부스트 1개를 사용합니다…" → [확인]이면 사용).
///
/// ⚠️ 이 팝업은 **시안이 없다** — 프라임 해지 팝업의 틀·느낌표를 빌리고, 버튼은 그림이 있는
/// [사용하기 (1개)] · [아니요]로 둔다(`확인` 그림이 없다, 10 §0-7).
Future<bool?> showBoostUseConfirm(BuildContext context) =>
    showShopPopup<bool>(context, (_) => const _BoostUseConfirm());

const _titleStyle = TextStyle(
  color: Colors.black,
  fontSize: 64,
  fontWeight: FontWeight.w900,
  height: 1,
);
const _nameStyle = TextStyle(
  color: Color(0xFF080B0E),
  fontSize: 60,
  fontWeight: FontWeight.w800,
  height: 1,
);
const _headStyle = TextStyle(
  color: Colors.black,
  fontSize: 46,
  fontWeight: FontWeight.w500,
  height: 1,
);

/// 팝업 가운데 정렬 그림(틀 폭 982 기준).
Widget _centered(String asset, Size size, double top) => Positioned(
  left: (982 - size.width) / 2,
  top: top,
  child: ArtImage(asset, width: size.width, height: size.height, scale: 1),
);

Widget _centeredText(String text, TextStyle style, double top) => Positioned(
  left: 20,
  right: 20,
  top: top - style.fontSize! * 0.1,
  child: Text(text, textAlign: TextAlign.center, style: style),
);

Widget _button(String asset, double left, double top, VoidCallback onTap) => Positioned(
  left: left,
  top: top,
  child: ShopArtButton(asset: asset, width: 808, height: 139, onTap: onTap),
);

class _ItemPurchased extends ConsumerWidget {
  const _ItemPurchased({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final kind = ShopKind.of(product.kind)!;
    final maxPhotos = ref.watch(catalogProvider).valueOrNull?.maxPhotosPass ?? 9;
    final (icon, iconSize) = kind.popupIcon;

    return ShopPopup(
      frame: '$itemDir/frame_buypopup.png',
      size: const Size(982, 1820),
      origin: const Offset(50, 359),
      children: (x, y) => [
        _centered('$itemDir/icon_notice.png', const Size(164, 164), y(407)),
        _centeredText(l10n.lunaPurchasedTitle, _titleStyle, y(623)),
        Positioned(
          left: x(88),
          top: y(744),
          child: const ArtImage('$itemDir/frame_itemname.png', width: 906, height: 166, scale: 1),
        ),
        Positioned(
          left: x(184),
          top: y(744),
          height: 166,
          child: Row(
            children: [
              ArtImage(icon, width: iconSize.width, height: iconSize.height, scale: 1),
              SizedBox(width: 320 - 184 - iconSize.width),
              Text(kind.productName(l10n, product), style: _nameStyle),
            ],
          ),
        ),
        Positioned(
          left: x(108),
          top: y(992) - 6,
          child: Text(kind.benefitHead(l10n), style: _headStyle),
        ),
        Positioned(
          left: x(89),
          top: y(1063),
          child: Stack(
            children: [
              const ArtImage('$itemDir/frame_iteminfo.png', width: 903, height: 625, scale: 1),
              ShopBenefitList(
                size: const Size(903, 625),
                items: kind.benefits(l10n, maxPhotos),
                onPurple: false,
                gap: 26,
              ),
            ],
          ),
        ),
        _button('$itemDir/button_checkitem.png', x(134), y(1769),
            () => Navigator.of(context).pop(true)),
        _button('$itemDir/button_popupexit.png', x(134), y(1963),
            () => Navigator.of(context).pop(false)),
      ],
    );
  }
}

class _PrimePurchased extends StatelessWidget {
  const _PrimePurchased({required this.plan});

  final PrimePlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    // 프라임 혜택 다섯 줄 — 구매 화면과 같은 문구(부스트 매수는 1개월 플랜 기준).
    final boosts = plan.boosts['POST_BOOST'] ?? 10;
    final items = <(String, String)>[
      (l10n.primeBenefitAlbum, l10n.primeBenefitAlbumDesc),
      (l10n.primeBenefitBoost(boosts), l10n.primeBenefitBoostDesc),
      (l10n.primeBenefitChat, l10n.primeBenefitChatDesc),
      (l10n.primeBenefitTranslate, l10n.primeBenefitTranslateDesc),
      (l10n.primeBenefitNoAds, l10n.primeBenefitNoAdsDesc),
    ];

    return ShopPopup(
      frame: '$itemDir/frame_primebuypopup.png',
      size: const Size(982, 2105),
      origin: const Offset(50, 261),
      children: (x, y) => [
        _centered('$itemDir/icon_notice.png', const Size(164, 164), y(315)),
        _centeredText(l10n.lunaPurchasedTitle, _titleStyle, y(529)),
        Positioned(
          left: x(89),
          top: y(663),
          child: const ArtImage('$itemDir/frame_itemname.png', width: 906, height: 166, scale: 1),
        ),
        Positioned(
          left: x(184),
          top: y(663),
          height: 166,
          child: Row(
            children: [
              const ArtImage('$itemDir/icon_prime_l.png', width: 107, height: 104, scale: 1),
              const SizedBox(width: 320 - 184 - 107),
              Text(l10n.primePurchasedName(plan.months), style: _nameStyle),
            ],
          ),
        ),
        Positioned(
          left: x(108),
          top: y(907) - 6,
          child: Text(l10n.primePurchasedHead, style: _headStyle),
        ),
        Positioned(
          left: x(89),
          top: y(982),
          child: Stack(
            children: [
              const ArtImage('$itemDir/frame_primeiteminfo.png', width: 903, height: 885, scale: 1),
              ShopBenefitList(
                size: const Size(903, 885),
                items: items,
                onPurple: false,
                gap: 22,
              ),
            ],
          ),
        ),
        _button('$itemDir/button_checkitem.png', x(134), y(1950),
            () => Navigator.of(context).pop(true)),
        _button('$itemDir/button_popupexit.png', x(134), y(2140),
            () => Navigator.of(context).pop(false)),
      ],
    );
  }
}

class _BoostUseConfirm extends StatelessWidget {
  const _BoostUseConfirm();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    const sub = '$shopDir/prime_sub/sub_end';
    // 좌표는 프라임 해지 팝업(시안 `SubEnd`)과 같은 틀.
    return ShopPopup(
      frame: '$sub/frame_subcandelpopup.png',
      size: const Size(993, 1218),
      origin: const Offset(51, 863),
      children: (x, y) => [
        Positioned(
          left: (993 - 164) / 2,
          top: y(916),
          child: const ArtImage('$sub/icon_notice.png', width: 164, height: 164, scale: 1),
        ),
        Positioned(
          left: 30,
          right: 30,
          top: y(1147) - 6,
          child: Text(
            l10n.shopBoostUseTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 58,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        Positioned(
          left: 40,
          right: 40,
          top: y(1283),
          child: Text(
            l10n.shopBoostUseBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 45,
              fontWeight: FontWeight.w500,
              height: 1.58,
            ),
          ),
        ),
        Positioned(
          left: x(136),
          top: y(1671),
          child: ShopArtButton(
            asset: '$itemDir/button_boostuse.png',
            width: 808,
            height: 139,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ),
        Positioned(
          left: x(136),
          top: y(1864),
          child: ShopArtButton(
            asset: '$sub/button_cancel.png',
            width: 808,
            height: 139,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    );
  }
}
