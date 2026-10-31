import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import '../widgets/luna_popups.dart';
import '../widgets/store_widgets.dart';
import 'luna_charge_screen.dart';

/// 루나 상점 (기획서 261011 10-2 · 시안 `Scene_Shop/LunaShop`).
///
/// 보유량 배너 + 상품 카드 셋(포스트 부스트 · 포스트 앨범 패스 · 자동 번역). 카드마다 옵션 둘 중 하나를 고르고
/// 아래 버튼을 누른다. 버튼은 상태에 따라 그림이 바뀐다:
///
/// | 상태 | 버튼 | 누르면 |
/// |---|---|---|
/// | 없음 | [구매하기] | 루나로 산다 → 구매 완료 팝업 |
/// | 부스트 보유·안 씀 | [사용하기 ›] | 상품 관리 팝업(사용 전) |
/// | 쓰는 중(부스트 1시간 · 패스 기간) | [사용 중 ›] | 상품 관리 팝업 |
///
/// 📌 전달 이름이 뜻과 엇갈려 있다 — `button_lunashopuse`가 **`사용 중`**, `button_lunashopusing`이 **`사용하기`** 다.
///
/// 가격·구성은 서버 카탈로그(`GET /store/products`)에서 온다. 옵션 그림은 `5개`·`10개`·`7일`·`30일`이
/// 구워져 있어 **그 구성만** 그린다(다른 구성이 설정에 생기면 그림부터 받아야 한다).
class LunaStoreScreen extends ConsumerStatefulWidget {
  const LunaStoreScreen({super.key, this.focus});

  /// 다른 화면의 문([부스트]·[포스트 앨범]·[번역 패스])으로 들어왔을 때의 상품. 이미 갖고 있으면
  /// 들어오자마자 그 상품 관리 팝업을 연다(기획서 10-2-1 `사용`·`사용 정보` 화면).
  final String? focus;

  static Route<void> route({String? focus}) =>
      MaterialPageRoute(builder: (_) => LunaStoreScreen(focus: focus));

  @override
  ConsumerState<LunaStoreScreen> createState() => _LunaStoreScreenState();
}

const _dir = '$shopDir/luna_shop';

/// 카드 윗변(시안 49, 590 · 1227 · 1863).
const _cardTops = [590.0, 1227.0, 1863.0];

class _LunaStoreScreenState extends ConsumerState<LunaStoreScreen> {
  /// kind → 고른 상품 id. 처음엔 각 카드의 첫 옵션.
  final Map<String, String> _selected = {};
  bool _busy = false;
  bool _focusHandled = false;

  @override
  void initState() {
    super.initState();
    // 루나·보유 상태는 다른 화면에서도 바뀐다 — 들어올 때마다 다시 읽는다(클라 갱신 방침).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(walletProvider.notifier).refresh();
    });
  }

  bool _owns(Wallet w, String kind) => kind == StoreKind.postBoost
      ? w.isBoostOn(kind) || w.stockOf(kind) > 0
      : w.has(kind);

  void _maybeOpenFocus(Wallet wallet) {
    if (_focusHandled || widget.focus == null) return;
    _focusHandled = true;
    if (!_owns(wallet, widget.focus!)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showLunaManagePopup(context, widget.focus!);
    });
  }

  Future<void> _buy(LunaProduct product) async {
    final l10n = L10n.of(context);
    setState(() => _busy = true);
    final error = await ref
        .read(storeActionsProvider)
        .purchaseWithLuna(product.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(l10n, error))));
      return;
    }
    await showLunaPurchasedPopup(context, product);
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
      final w = wallet.value!;
      final c = catalog.value!;
      _maybeOpenFocus(w);
      body = ShopCanvas(
        contentBottom: _cardTops.last + 589,
        gaps: const [(269, 24), (349, 24), (590, 36), (1227, 30), (1863, 30)],
        children: (y) => [
          // 타이틀은 언어마다 폭이 다르다(393 · 475) — 시안 시작점(302)은 같게 둔다.
          shopArt('$_dir/title_lunashop.png', 302, y(145), 393, 75),
          shopClose(context, y(133)),
          shopSubtitle(l10n.lunaStoreSubtitle, y(269)),
          ...shopBalance(
            banner: '$_dir/banner_luna.png',
            luna: w.luna,
            button: '$_dir/button_lunacharge.png',
            buttonSize: const Size(371, 90),
            buttonAt: const Offset(626, 398),
            onTap: () => Navigator.of(
              context,
            ).push(LunaChargeScreen.route(fromShop: true)),
            y: y,
          ),
          for (var i = 0; i < ShopKindArt.all.length; i++)
            ..._card(l10n, ShopKindArt.all[i], y(_cardTops[i]), w, c),
        ],
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(backgroundColor: Colors.white, body: body),
    );
  }

  /// 상품 카드 하나(981×589). [top]은 이미 당겨진 화면 y다.
  List<Widget> _card(
    L10n l10n,
    ShopKindArt art,
    double top,
    Wallet w,
    ProductCatalog c,
  ) {
    final options = c
        .optionsOf(art.kind)
        .where((p) => art.optionAsset(p, false) != null)
        .take(2)
        .toList();
    if (options.isEmpty) return const [];
    final selectedId = _selected[art.kind] ?? options.first.id;
    final selected = options.firstWhere(
      (p) => p.id == selectedId,
      orElse: () => options.first,
    );

    final active = art.isBoost ? w.isBoostOn(art.kind) : w.has(art.kind);
    final owned = art.isBoost && w.stockOf(art.kind) > 0;
    final (button, onTap) = active
        ? (
            '$_dir/button_lunashopuse.png',
            () => showLunaManagePopup(context, art.kind),
          )
        : owned
        ? (
            '$_dir/button_lunashopusing.png',
            () => showLunaManagePopup(context, art.kind),
          )
        : ('$_dir/button_lunashopbuy.png', _busy ? null : () => _buy(selected));

    final desc = switch (art.kind) {
      StoreKind.postBoost => l10n.lunaShopDescBoost,
      StoreKind.albumPass => l10n.lunaShopDescAlbum(c.maxPhotosPass),
      _ => l10n.lunaShopDescTrans,
    };
    final describeAt = switch (art.kind) {
      StoreKind.postBoost => const Offset(110, 382),
      StoreKind.albumPass => const Offset(116, 381),
      _ => const Offset(147, 383),
    };

    return [
      shopArt('$_dir/frame_lunashopinfo.png', 49, top, 981, 589),
      shopArt(art.icon, 87, top + 39, art.iconSize.width, art.iconSize.height),
      shopArt(
        art.title,
        219,
        top + 61,
        art.titleSize.width,
        art.titleSize.height,
      ),
      // 그림 바탕이 불투명해 글자보다 먼저 깐다(넷째 줄이 가려졌다).
      shopArt(
        art.describe,
        describeAt.dx,
        top + describeAt.dy,
        art.describeSize.width,
        art.describeSize.height,
      ),
      Positioned(
        left: 87,
        top: top + 160,
        width: 560 - 87,
        child: Text(
          desc,
          style: const TextStyle(
            color: ShopColors.ink,
            fontSize: 39,
            fontWeight: FontWeight.w700,
            height: 1.36,
          ),
        ),
      ),
      for (var i = 0; i < options.length; i++)
        Positioned(
          left: 569,
          top: top + (i == 0 ? 139 : 279),
          child: _OptionButton(
            asset: art.optionAsset(options[i], options[i].id == selected.id)!,
            price: options[i].price,
            onTap: () => setState(() => _selected[art.kind] = options[i].id),
          ),
        ),
      // `20% 할인` — 둘째 옵션 왼쪽 위에 걸친다. 글자는 서버 설정 표시값.
      for (var i = 0; i < options.length; i++)
        if (options[i].discount > 0)
          Positioned(
            left: 570,
            top: top + (i == 0 ? 117 : 257),
            child: SizedBox(
              width: 156,
              height: 53,
              child: Stack(
                children: [
                  const ArtImage(
                    '$_dir/icon_discount.png',
                    width: 156,
                    height: 53,
                    scale: 1,
                  ),
                  Center(
                    child: Text(
                      l10n.storeDiscount(options[i].discount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      Positioned(
        left: 569,
        top: top + 432,
        child: ShopArtButton(
          asset: button,
          width: 425,
          height: 104,
          onTap: onTap,
        ),
      ),
    ];
  }
}

/// 옵션 하나(435×104) — `5개 | ★`까지 그림, 금액은 별 오른쪽(그림 안 x 301)에 폰트로.
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.asset,
    required this.price,
    required this.onTap,
  });

  final String asset;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShopArtButton(
      asset: asset,
      width: 435,
      height: 104,
      onTap: onTap,
      overlay: Positioned(
        left: 301,
        top: 0,
        bottom: 0,
        child: Center(
          child: Text(
            shopNumber(price),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 52,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
