import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import '../widgets/store_widgets.dart';
import 'luna_store_screen.dart';

/// 루나 충전 (기획서 261011 10-2 `[루나 충전]` · 시안 `Scene_Shop/LunaCharge`).
///
/// 보유량 배너 + 충전 카드 다섯. 카드는 위에서부터 **병 그림 1~5**와 한 줄 문구가 정해져 있고,
/// 개수·금액·`○% 할인`·리본(`인기 상품`·`최고 할인`)은 서버 카탈로그에서 온다(`app.store.luna-packs`).
///
/// 🚧 **실제 결제창이 없다**(막힌 것 E) — 금액 버튼은 개발용 목 결제(`dev-` 토큰 → 서버 검증)로 충전한다.
/// 금액은 표시용 기준가(원)다. 결제창이 붙으면 스토어 SDK의 현지 가격으로 바꾼다.
class LunaChargeScreen extends ConsumerStatefulWidget {
  const LunaChargeScreen({super.key, this.fromShop = false});

  /// 루나 상점에서 왔으면 [루나 상점가기]가 뒤로 간다(상점을 두 겹 쌓지 않는다).
  final bool fromShop;

  static Route<void> route({bool fromShop = false}) =>
      MaterialPageRoute(builder: (_) => LunaChargeScreen(fromShop: fromShop));

  @override
  ConsumerState<LunaChargeScreen> createState() => _LunaChargeScreenState();
}

const _dir = '$shopDir/luna_charge';

/// 카드 윗변(시안 49, 576 · 961 · 1345 · 1726 · 2105).
const _cardTops = [576.0, 961.0, 1345.0, 1726.0, 2105.0];

/// 병 그림 — (크기, 카드 안 왼쪽 위). 시안 좌표값 그대로.
const _bottles = [
  (Size(142, 228), Offset(123, 66)),
  (Size(182, 219), Offset(105, 77)),
  (Size(207, 236), Offset(90, 73)),
  (Size(222, 237), Offset(82, 68)),
  (Size(224, 290), Offset(84, 47)),
];

class _LunaChargeScreenState extends ConsumerState<LunaChargeScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(walletProvider.notifier).refresh();
    });
  }

  Future<void> _charge(LunaPack pack) async {
    final l10n = L10n.of(context);
    setState(() => _busy = true);
    // 스토어 결제창이 붙기 전까지는 개발용 토큰으로 서버 검증을 태운다(01 §1.8 ①, 막힌 것 E).
    final error = await ref
        .read(storeActionsProvider)
        .verifyPurchase(
          productId: pack.productId,
          purchaseToken:
              'dev-${pack.productId}-${DateTime.now().millisecondsSinceEpoch}',
        );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error == null
                ? l10n.chargeDone(pack.total)
                : errorMessage(l10n, error),
          ),
        ),
      );
  }

  void _goShop() {
    final nav = Navigator.of(context);
    if (widget.fromShop) {
      nav.pop();
    } else {
      nav.pushReplacement(LunaStoreScreen.route());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final wallet = ref.watch(walletProvider);
    final catalog = ref.watch(catalogProvider);

    Widget body;
    if (wallet.valueOrNull == null || catalog.valueOrNull == null) {
      final failed = wallet.hasError || catalog.hasError;
      body = Center(
        child: failed
            ? Text(
                l10n.storeLoadFailed,
                style: const TextStyle(color: ShopColors.sub),
              )
            : const CircularProgressIndicator(color: ShopColors.purple),
      );
    } else {
      final packs = [...catalog.value!.lunaPacks]
        ..sort((a, b) => a.total.compareTo(b.total));
      body = ShopCanvas(
        contentBottom: _cardTops.last + 356,
        gaps: const [
          (265, 24),
          (349, 24),
          (576, 28),
          (961, 18),
          (1345, 18),
          (1726, 18),
          (2105, 18),
        ],
        children: (y) => [
          shopArt('$_dir/title_lunacharge.png', 303, y(140), 390, 78),
          shopClose(context, y(133)),
          shopSubtitle(l10n.chargeSubtitle, y(265)),
          ...shopBalance(
            banner: '$_dir/banner_luna.png',
            luna: wallet.value!.luna,
            button: '$_dir/button_golunashop.png',
            buttonSize: const Size(373, 85),
            buttonAt: const Offset(622, 398),
            onTap: _goShop,
            y: y,
          ),
          for (var i = 0; i < packs.length && i < _cardTops.length; i++)
            ..._card(l10n, i, packs[i], y(_cardTops[i])),
        ],
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(backgroundColor: Colors.white, body: body),
    );
  }

  /// 충전 카드 하나(981×356). [top]은 이미 당겨진 화면 y다.
  List<Widget> _card(L10n l10n, int i, LunaPack pack, double top) {
    final (size, at) = _bottles[i];
    final tags = [
      l10n.chargeTag1,
      l10n.chargeTag2,
      l10n.chargeTag3,
      l10n.chargeTag4,
      l10n.chargeTag5,
    ];
    return [
      shopArt('$_dir/frame_lunacharge.png', 49, top, 981, 356),
      shopArt(
        '$_dir/icon_chargeitem${i + 1}.png',
        at.dx,
        top + at.dy,
        size.width,
        size.height,
      ),
      // `루나 100개` — 숫자만 보라.
      Positioned(
        left: 349,
        top: top + 46,
        width: 770 - 349,
        height: 76,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                color: Colors.black,
                fontSize: 68,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
              children: [
                TextSpan(text: l10n.chargeLunaPrefix),
                TextSpan(
                  text: shopNumber(pack.total),
                  style: const TextStyle(color: ShopColors.purple),
                ),
                TextSpan(text: l10n.chargeLunaSuffix),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 349,
        top: top + 138,
        right: 40,
        child: Text(
          tags[i],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ShopColors.tag,
            fontSize: 41,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
      if (pack.discountPercent > 0)
        Positioned(
          left: 781,
          top: top + 36,
          child: SizedBox(
            width: 213,
            height: 73,
            child: Stack(
              children: [
                const ArtImage(
                  '$_dir/icon_discountmark.png',
                  width: 213,
                  height: 73,
                  scale: 1,
                ),
                // `할인`은 그림, 숫자는 그 왼쪽 흰 칸에.
                Positioned(
                  left: 8,
                  width: 125 - 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      l10n.chargeDiscountPercent(pack.discountPercent),
                      style: const TextStyle(
                        color: ShopColors.red,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      Positioned(
        left: 671,
        top: top + 238,
        child: ShopArtButton(
          asset: '$_dir/button_chargeprice.png',
          width: 321,
          height: 79,
          onTap: _busy ? null : () => _charge(pack),
          overlay: Center(
            child: Text(
              l10n.chargePrice(shopNumber(pack.price)),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
      // 리본은 카드 왼쪽 위에 걸친다 — 카드보다 나중에 그려야 위로 온다.
      if (pack.badge == 'POPULAR')
        shopArt('$_dir/icon_popular.png', 21, top - 20, 264, 93),
      if (pack.badge == 'BEST')
        shopArt('$_dir/icon_discount.png', 27, top - 29, 268, 103),
    ];
  }
}
