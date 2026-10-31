import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import 'store_widgets.dart';

/// 상품 관리 팝업(시안 `Scene_Shop/LunaBuyPrev`) — 상점 카드의 [사용하기 ›]·[사용 중 ›]과
/// [보유 상품 확인]이 연다. 기획서 261011 10-2-1 `사용`·`사용 정보`, 10-2-2·10-2-3 `관리` 화면이 이것이다.
///
/// | 상품 | 시안 | 버튼 |
/// |---|---|---|
/// | 부스트(보유·안 씀) | `포스트 부스트 상품 관리_사용전` | [사용하기 (1개)] · [나가기] |
/// | 부스트(쓰는 중) | `…_사용후` — `이용 중` | [나가기] |
/// | 앨범 패스 · 자동 번역 | `포스트 앨범 상품 관리` · `자동 번역 상품 관리` | [나가기] |
///
/// 지갑을 지켜보므로 [사용하기]를 누르면 그 자리에서 `이용 중`으로 바뀐다.
Future<void> showLunaManagePopup(BuildContext context, String kind) =>
    showShopPopup<void>(context, (_) => _ManagePopup(kind: kind));

/// 구매 완료 팝업(시안 `Scene_Shop/LunaBuyAfter`). [보유 상품 확인] → 상품 관리 팝업.
Future<void> showLunaPurchasedPopup(
  BuildContext context,
  LunaProduct product,
) async {
  final check = await showShopPopup<bool>(
    context,
    (_) => _PurchasedPopup(product: product),
  );
  if (check == true && context.mounted) {
    await showLunaManagePopup(context, product.kind);
  }
}

const _prev = '$shopDir/luna_buy_prev';
const _after = '$shopDir/luna_buy_after';

class _ManagePopup extends ConsumerStatefulWidget {
  const _ManagePopup({required this.kind});

  final String kind;

  @override
  ConsumerState<_ManagePopup> createState() => _ManagePopupState();
}

class _ManagePopupState extends ConsumerState<_ManagePopup> {
  bool _busy = false;

  Future<void> _useBoost() async {
    final l10n = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final error = await ref.read(storeActionsProvider).useBoost(widget.kind);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error == null ? l10n.boostUsed : errorMessage(l10n, error),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final art = ShopKindArt.of(widget.kind)!;
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;
    final maxPhotos =
        ref.watch(catalogProvider).valueOrNull?.maxPhotosPass ?? 9;

    return art.isBoost
        ? _boost(l10n, art, wallet, maxPhotos)
        : _pass(l10n, art, wallet, maxPhotos);
  }

  Widget _boost(L10n l10n, ShopKindArt art, Wallet wallet, int maxPhotos) {
    final active = wallet.activeBoost(widget.kind);
    final stock = wallet.stockOf(widget.kind);
    final minutes = active == null
        ? null
        : (active.remaining.inSeconds / 60).ceil();

    return ShopPopup(
      frame: '$_prev/frame_boostpopup.png',
      size: const Size(982, 2169),
      origin: const Offset(50, 281),
      children: (x, y) => [
        _centered(x, y, art.image, art.imageSize, 331),
        // 부스트는 제목 앞 아이콘이 없다(시안).
        Positioned(
          left: 0,
          right: 0,
          top: y(544) - 6,
          child: Text(
            art.name(l10n),
            textAlign: TextAlign.center,
            style: _titleStyle,
          ),
        ),
        if (active != null)
          _centered(x, y, '$_prev/icon_primeuse.png', const Size(233, 74), 623),
        Positioned(
          left: x(88),
          top: y(725),
          child: const ArtImage(
            '$_prev/frame_boostamount.png',
            width: 906,
            height: 166,
            scale: 1,
          ),
        ),
        // 보유량 숫자 — 그림 속 세로줄(576) 오른쪽 칸.
        Positioned(
          left: x(576),
          width: 994 - 576,
          top: y(725),
          height: 166,
          child: Center(child: Text(shopNumber(stock), style: _countStyle)),
        ),
        Positioned(
          left: x(88),
          top: y(925),
          child: const ArtImage(
            '$_prev/frame_boostubinfo.png',
            width: 912,
            height: 285,
            scale: 1,
          ),
        ),
        // 아직 안 썼으면 끝나는 시각이 없다.
        _value(
          x,
          y,
          active == null ? '-' : shopDateTime(active.expiresAt),
          1011,
        ),
        _value(
          x,
          y,
          minutes == null ? '-' : l10n.lunaRemainMinutes(minutes),
          1126,
        ),
        shopBenefitHead(art.benefitHead(l10n), x(108), y(1278)),
        Positioned(
          left: x(88),
          top: y(1364),
          child: ShopBenefitBox(
            asset: '$_prev/frame_iteminfo.png',
            items: art.benefits(l10n, maxPhotos),
          ),
        ),
        // 쓰는 중이거나 남은 게 없으면 [사용하기]가 없다(시안 사용후).
        if (active == null && stock > 0)
          Positioned(
            left: x(134),
            top: y(2050),
            child: ShopArtButton(
              asset: '$_prev/button_boostuse.png',
              width: 808,
              height: 139,
              onTap: _busy ? null : _useBoost,
            ),
          ),
        _exit(x, y, '$_prev/button_popupexit.png', 2243),
      ],
    );
  }

  Widget _pass(L10n l10n, ShopKindArt art, Wallet wallet, int maxPhotos) {
    final started = wallet.entitlementStartedAt[widget.kind];
    final expires = wallet.expiresAt(widget.kind);
    final total = started == null || expires == null
        ? null
        : (expires.difference(started).inHours / 24).round();
    final remaining = wallet.remainingDays(widget.kind);

    return ShopPopup(
      frame: '$_prev/frame_itempopup.png',
      size: const Size(982, 2065),
      origin: const Offset(50, 281),
      children: (x, y) => [
        _centered(x, y, art.image, art.imageSize, 332),
        // 아이콘 + `자동 번역 7일` 한 줄을 가운데에(시안 230, 559 · 363, 577).
        Positioned(
          left: 0,
          right: 0,
          top: y(559),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ArtImage(
                art.icon,
                width: art.iconSize.width,
                height: art.iconSize.height,
                scale: 1,
              ),
              const SizedBox(width: 30),
              Text(
                total == null
                    ? art.name(l10n)
                    : l10n.lunaItemDays(art.name(l10n), total),
                style: _titleStyle,
              ),
            ],
          ),
        ),
        if (expires != null)
          _centered(x, y, '$_prev/icon_primeuse.png', const Size(233, 74), 668),
        Positioned(
          left: x(88),
          top: y(799),
          child: const ArtImage(
            '$_prev/frame_albumsubinfo.png',
            width: 912,
            height: 405,
            scale: 1,
          ),
        ),
        _value(x, y, shopDateTime(started), 880),
        _value(x, y, shopDateTime(expires), 1001),
        _value(
          x,
          y,
          remaining == null ? '-' : l10n.lunaRemainDays(remaining),
          1117,
        ),
        shopBenefitHead(art.benefitHead(l10n), x(108), y(1288)),
        Positioned(
          left: x(88),
          top: y(1381),
          child: ShopBenefitBox(
            asset: '$_prev/frame_iteminfo.png',
            items: art.benefits(l10n, maxPhotos),
          ),
        ),
        _exit(x, y, '$_prev/button_popupexit.png', 2110),
      ],
    );
  }

  /// 정보 틀 오른쪽 값(오른쪽 끝 948, 가운데 [centerY]).
  Widget _value(
    double Function(double) x,
    double Function(double) y,
    String text,
    double centerY,
  ) => Positioned(
    right: 982 - x(948),
    top: y(centerY) - 30,
    height: 60,
    child: Center(child: Text(text, style: _valueStyle)),
  );

  Widget _exit(
    double Function(double) x,
    double Function(double) y,
    String asset,
    double top,
  ) => Positioned(
    left: x(134),
    top: y(top),
    child: ShopArtButton(
      asset: asset,
      width: 808,
      height: 139,
      onTap: () => Navigator.of(context).pop(),
    ),
  );
}

class _PurchasedPopup extends ConsumerWidget {
  const _PurchasedPopup({required this.product});

  final LunaProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final art = ShopKindArt.of(product.kind)!;
    final maxPhotos =
        ref.watch(catalogProvider).valueOrNull?.maxPhotosPass ?? 9;

    return ShopPopup(
      frame: '$_after/frame_lunapopup.png',
      // 시안 틀은 359~2175(1816) — 그림(1650)보다 길다.
      size: const Size(982, 1816),
      frameSize: const Size(982, 1650),
      origin: const Offset(50, 359),
      children: (x, y) => [
        _centered(x, y, '$_after/icon_notice.png', const Size(164, 164), 407),
        Positioned(
          left: 0,
          right: 0,
          top: y(623) - 4,
          child: Text(
            l10n.lunaPurchasedTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        Positioned(
          left: x(88),
          top: y(744),
          child: const ArtImage(
            '$_after/frame_itemname.png',
            width: 906,
            height: 166,
            scale: 1,
          ),
        ),
        Positioned(
          left: x(184),
          top: y(744),
          height: 166,
          child: Row(
            children: [
              ArtImage(
                art.icon,
                width: art.iconSize.width,
                height: art.iconSize.height,
                scale: 1,
              ),
              const SizedBox(width: 320 - 184 - 102),
              Text(art.productName(l10n, product), style: _titleStyle),
            ],
          ),
        ),
        shopBenefitHead(art.benefitHead(l10n), x(108), y(992)),
        Positioned(
          left: x(89),
          top: y(1063),
          child: ShopBenefitBox(
            asset: '$_after/frame_iteminfo.png',
            items: art.benefits(l10n, maxPhotos),
          ),
        ),
        Positioned(
          left: x(134),
          top: y(1769),
          child: ShopArtButton(
            asset: '$_after/button_checkitem.png',
            width: 808,
            height: 139,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ),
        Positioned(
          left: x(134),
          top: y(1963),
          child: ShopArtButton(
            asset: '$_after/button_popupexit.png',
            width: 808,
            height: 139,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    );
  }
}

/// 팝업 가운데 정렬 그림(틀 폭 982 기준).
Widget _centered(
  double Function(double) x,
  double Function(double) y,
  String asset,
  Size size,
  double top,
) => Positioned(
  left: (982 - size.width) / 2,
  top: y(top),
  child: ArtImage(asset, width: size.width, height: size.height, scale: 1),
);

const _titleStyle = TextStyle(
  color: Color(0xFF080B0E),
  fontSize: 60,
  fontWeight: FontWeight.w800,
  height: 1,
);

const _valueStyle = TextStyle(
  color: Colors.black,
  fontSize: 46,
  fontWeight: FontWeight.w700,
  height: 1,
);

const _countStyle = TextStyle(
  color: Colors.black,
  fontSize: 68,
  fontWeight: FontWeight.w700,
  height: 1,
);
