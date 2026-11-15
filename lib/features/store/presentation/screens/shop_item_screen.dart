import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import '../widgets/shop_popups.dart';
import '../widgets/store_widgets.dart';
import 'prime_screen.dart';

/// 상점 상품 하나 — 포스트 부스트 · 포스트 앨범 · 자동 번역 (기획서 261111 10-2·10-3·10-4, 시안 `Scene_Shop(New)`).
///
/// **구매 화면**과 **관리 화면**이 한 화면이다. 들어올 때 보유 상태로 고른다
/// (기획서 "미 사용 보유량/기간이 존재할 경우 … [관리] 화면 출력"):
///
/// | 상태 | 화면 | 아래 |
/// |---|---|---|
/// | 없음 | 구매 — 설명 · 그림 · 상품 두 줄(가격 버튼) · `또는` · [프라임 멤버십 구독 시 ›] · 혜택 | — |
/// | 있음 | 관리 — `보유량`/`보유기간` · [프라임 구독분]·[상점 구매분] · `사용 정보` · 혜택 | 부스트: [사용하기 (1개)] → 확인 팝업 / 그 밖: [나가기] |
///
/// 가격 버튼을 누르면 결제창 → 구매 완료 팝업 → [보유 상품 확인]이면 관리 화면으로 바뀐다.
/// 🚧 **실제 결제창이 없다**(막힌 것 E) — 개발용 목 결제(`dev-` 토큰 → 서버 검증)로 산다.
class ShopItemScreen extends ConsumerStatefulWidget {
  const ShopItemScreen({super.key, required this.kind});

  /// `POST_BOOST` · `ALBUM_PASS` · `TRANSLATE_PASS`
  final String kind;

  static Route<void> route(String kind) =>
      MaterialPageRoute(builder: (_) => ShopItemScreen(kind: kind));

  @override
  ConsumerState<ShopItemScreen> createState() => _ShopItemScreenState();
}

const _textWhite = TextStyle(
  color: Colors.white,
  fontSize: 39,
  fontWeight: FontWeight.w500,
  height: 1.38,
);
const _head = TextStyle(
  color: ShopColors.head,
  fontSize: 50,
  fontWeight: FontWeight.w800,
  height: 1,
);

class _ShopItemScreenState extends ConsumerState<ShopItemScreen> {
  /// null이면 보유 상태로 고른다. [보유 상품 확인]을 누르면 관리 화면으로 고정.
  bool? _manage;
  bool _busy = false;

  ShopKind get _kind => ShopKind.of(widget.kind)!;

  @override
  void initState() {
    super.initState();
    // 보유 상태는 다른 화면·시간(만료)에 따라 바뀐다 — 들어올 때마다 다시 읽는다(클라 갱신 방침).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(walletProvider.notifier).refresh();
    });
  }

  Future<void> _buy(ShopProduct product) async {
    final l10n = L10n.of(context);
    setState(() => _busy = true);
    // 스토어 결제창이 붙기 전까지는 개발용 토큰으로 서버 검증을 태운다(01 §1.8 ①, 막힌 것 E).
    final error = await ref.read(storeActionsProvider).verifyPurchase(
      productId: product.id,
      purchaseToken: 'dev-${product.id}-${DateTime.now().millisecondsSinceEpoch}',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(l10n, error))));
      return;
    }
    final check = await showItemPurchasedPopup(context, product);
    if (check == true && mounted) setState(() => _manage = true);
  }

  Future<void> _useBoost() async {
    final l10n = L10n.of(context);
    final ok = await showBoostUseConfirm(context);
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final error = await ref.read(storeActionsProvider).useBoost(widget.kind);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(l10n, error))));
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
            ? Text(l10n.storeLoadFailed, style: const TextStyle(color: Colors.white))
            : const CircularProgressIndicator(color: Colors.white),
      );
    } else {
      final w = wallet.value!;
      final c = catalog.value!;
      body = (_manage ?? w.owns(widget.kind))
          ? _manageView(l10n, w, c)
          : _buyView(l10n, c);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF3A1590),
        body: body is ShopCanvas
            ? body
            : Stack(children: [
                Positioned.fill(
                  child: Image.asset('$itemDir/back_shop.png', fit: BoxFit.cover),
                ),
                body,
              ]),
      ),
    );
  }

  /// 타이틀 줄 — 큰 아이콘 · 이름 그림 · [X](964, 128).
  List<Widget> _header(ShopY y) {
    final (icon, iconSize, iconAt) = _kind.bigIcon;
    final (title, titleSize, titleAt) = _kind.title;
    return [
      shopArt(icon, iconAt.dx, y(iconAt.dy), iconSize.width, iconSize.height),
      shopArt(title, titleAt.dx, y(titleAt.dy), titleSize.width, titleSize.height),
      Positioned(
        left: 964 - 24,
        top: y(128) - 24,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).maybePop(),
          child: const Padding(
            padding: EdgeInsets.all(24), // 손가락 자리 — 그림(64)보다 넓게
            child: ArtImage('$itemDir/button_shopexit.png', width: 64, height: 64, scale: 1),
          ),
        ),
      ),
    ];
  }

  // ── 구매 화면 ──

  Widget _buyView(L10n l10n, ProductCatalog c) {
    final options = c.optionsOf(widget.kind).take(2).toList();
    final (hero, heroSize, heroAt) = _kind.hero;
    final descX = switch (widget.kind) {
      StoreKind.postBoost => 89.0,
      StoreKind.albumPass => 98.0,
      _ => 134.0,
    };
    const rowTops = [718.0, 971.0];

    return ShopCanvas(
      background: '$itemDir/back_shop.png',
      contentBottom: 1751 + 760,
      gaps: const [(718, 80), (1235, 30), (1331, 30), (1676, 70), (1751, 20)],
      children: (y) => [
        ..._header(y),
        shopText(_kind.description(l10n, c.maxPhotosPass), descX, y(264), _textWhite,
            width: 1070 - descX),
        shopArt(hero, heroAt.dx, y(heroAt.dy), heroSize.width, heroSize.height),
        for (var i = 0; i < options.length; i++)
          ..._productRow(l10n, options[i], i, y(rowTops[i])),
        Positioned(
          left: 0,
          right: 0,
          top: y(1235) - 6,
          child: Text(
            l10n.shopOr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        // [프라임 멤버십 구독 시 ›] — 프라임 구매 화면으로(기획서 10-2~10-4 "프라임 멤버십 배너").
        Positioned(
          left: 84,
          top: y(1331),
          child: ShopArtButton(
            asset: _kind.primeBanner,
            width: 912,
            height: 232,
            onTap: () => Navigator.of(context).push(PrimeScreen.route()),
          ),
        ),
        shopText(_kind.benefitHead(l10n), 102, y(1676), _head),
        shopArt('$itemDir/frame_shopinfo.png', 84, y(1751), 908, 760),
        Positioned(
          left: 84,
          top: y(1751),
          child: ShopBenefitList(
            size: const Size(908, 760),
            items: _kind.benefits(l10n, c.maxPhotosPass),
          ),
        ),
      ],
    );
  }

  /// 상품 한 줄(909×221) — 작은 아이콘 · `포스트 부스트 5개`(숫자만 보라) · 한 줄 · 가격 버튼 · `○% 할인`.
  List<Widget> _productRow(L10n l10n, ShopProduct p, int i, double top) {
    final (icon, iconSize) = _kind.smallIcon;
    return [
      shopArt('$itemDir/frame_shoplist.png', 84, top, 909, 221),
      shopArt(icon, 143, top + 32, iconSize.width, iconSize.height),
      Positioned(
        left: 261,
        top: top + 38,
        width: 733 - 261 - 12,
        height: 70,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                color: Colors.black,
                fontSize: 54,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
              children: [
                TextSpan(text: '${_kind.name(l10n)} '),
                TextSpan(
                  text: '${p.isBoost ? p.quantity : p.durationDays}',
                  style: const TextStyle(color: ShopColors.purple),
                ),
                TextSpan(text: p.isBoost ? l10n.shopUnitCount : l10n.shopUnitDays),
              ],
            ),
          ),
        ),
      ),
      shopText(
        i == 0 ? l10n.shopTagFirst : l10n.shopTagSecond,
        144,
        top + 135,
        const TextStyle(
          color: ShopColors.name,
          fontSize: 42,
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      ),
      Positioned(
        left: 623,
        top: top + 119,
        child: ShopArtButton(
          asset: '$itemDir/button_shopprice.png',
          width: 321,
          height: 79,
          onTap: _busy ? null : () => _buy(p),
          overlay: Center(
            child: Text(
              l10n.shopPrice(shopNumber(p.price)),
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
      // `○% 할인` — `할인`은 그림, 숫자는 그 왼쪽 흰 칸에. 값은 서버 설정 표시값.
      if (p.discount > 0)
        Positioned(
          left: 733,
          top: top + 25,
          child: SizedBox(
            width: 213,
            height: 73,
            child: Stack(
              children: [
                const ArtImage('$itemDir/icon_discountmark.png',
                    width: 213, height: 73, scale: 1),
                Positioned(
                  left: 8,
                  width: 125 - 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      l10n.shopDiscountPercent(p.discount),
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
    ];
  }

  // ── 관리 화면 ──

  Widget _manageView(L10n l10n, Wallet w, ProductCatalog c) {
    final (holdTitle, holdSize, holdAt) = _kind.holdingTitle;
    final boost = w.boostOf(widget.kind);
    final pass = w.passOf(widget.kind);

    // 숫자 — 부스트는 매수, 패스는 남은 일수(프라임 구독분 + 상점 구매분).
    final (total, prime, store) = _kind.isBoost
        ? (boost.total, boost.prime, boost.store)
        : (pass.totalDays, pass.primeDays, pass.storeDays);
    final unit = _kind.isBoost ? l10n.shopUnitCount : l10n.shopUnitDays;

    // `이용 중` — 지금 흐르는 쪽 칸에. 사용 정보도 그쪽 것.
    final String? running;
    final DateTime? startedAt;
    final DateTime? expiresAt;
    final String remaining;
    if (_kind.isBoost) {
      running = boost.active ? boost.activeSource : null;
      startedAt = running == null ? null : boost.activeStartedAt;
      expiresAt = running == null ? null : boost.activeExpiresAt;
      remaining = expiresAt == null
          ? '-'
          : l10n.lunaRemainMinutes(
              (expiresAt.difference(DateTime.now()).inSeconds / 60).ceil().clamp(0, 60),
            );
    } else {
      running = pass.runningSource;
      startedAt = pass.runningStartedAt;
      expiresAt = pass.runningExpiresAt;
      final days = running == 'PRIME' ? pass.primeDays : pass.storeDays;
      remaining = running == null ? '-' : l10n.lunaRemainDays(days);
    }
    final canUse = _kind.isBoost && !boost.active && boost.total > 0;

    return ShopCanvas(
      background: '$itemDir/back_shop.png',
      contentBottom: 2376 + 139,
      gaps: const [(309, 30), (665, 30), (1055, 20), (1610, 40), (1682, 10), (2376, 30)],
      children: (y) => [
        ..._header(y),
        shopArt(holdTitle, holdAt.dx, y(holdAt.dy), holdSize.width, holdSize.height),
        // `15개` — 숫자는 노랑, 단위는 흰색. 가운데.
        Positioned(
          left: 0,
          right: 0,
          top: y(446) - 26,
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 176,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -6,
              ),
              children: [
                TextSpan(text: '$total', style: const TextStyle(color: ShopColors.yellow)),
                TextSpan(text: unit),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        ..._column(_kind.primeColumn, 53, y(700), prime),
        ..._column(_kind.storeColumn, 557, y(700), store),
        if (running != null)
          shopArt('$shopDir/prime_sub/sub_manage/icon_primeuse.png', running == 'PRIME' ? 89 : 593, y(665), 233, 74),
        shopText(l10n.shopUseInfo, 100, y(1055), _head),
        shopArt('$itemDir/frame_useinfo.png', 84, y(1132), 914, 414),
        _infoValue(shopDateTime(startedAt), y(1217)),
        _infoValue(shopDateTime(expiresAt), y(1339)),
        _infoValue(remaining, y(1463)),
        shopText(_kind.benefitHead(l10n), 100, y(1610), _head),
        shopArt('$itemDir/frame_itemexplan.png', 84, y(1682), 908, 643),
        Positioned(
          left: 84,
          top: y(1682),
          child: ShopBenefitList(
            size: const Size(908, 643),
            items: _kind.benefits(l10n, c.maxPhotosPass),
            gap: 28,
          ),
        ),
        // 부스트를 쓸 수 있으면 [사용하기 (1개)], 그 밖엔 [나가기](기획서 10-2 "사용 적용 시 [나가기]로 변경").
        Positioned(
          left: 143,
          top: y(2376),
          child: ShopArtButton(
            asset: canUse ? '$itemDir/button_boostuse.png' : '$itemDir/button_popupexit.png',
            width: 808,
            height: 139,
            onTap: canUse
                ? (_busy ? null : _useBoost)
                : () => Navigator.of(context).maybePop(),
          ),
        ),
      ],
    );
  }

  /// [프라임 구독분]·[상점 구매분] 칸(473×299) — 글은 그림, 숫자만 알약(가운데 아래) 안에.
  List<Widget> _column(String asset, double left, double top, int value) => [
    shopArt(asset, left, top, 473, 299),
    Positioned(
      left: left,
      width: 473,
      top: top + 233 - 44,
      height: 88,
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(
            color: ShopColors.purple,
            fontSize: 80,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    ),
  ];

  /// 사용 정보 틀의 오른쪽 값(오른쪽 끝 950, 가운데 [centerY]).
  Widget _infoValue(String text, double centerY) => Positioned(
    right: 1080 - 950,
    top: centerY - 30,
    height: 60,
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 47,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    ),
  );
}
