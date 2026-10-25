import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';

/// 프라임 멤버십 (기획서 261011 10-1 · `Scene_Shop/PrimeSub`).
///
/// 한 화면이 구독 상태에 따라 세 모습이 된다:
///
/// | 상태 | 시안 | 아래 버튼 |
/// |---|---|---|
/// | 구독 전 | `SubStart` — 요금제 카드(가로로 넘김) | [구매하기 ₩…] |
/// | 구독 중(자동 갱신) | `SubManage` — 구독 정보 | [구독 관리] → 해지 팝업(`SubEnd`) |
/// | 해지 신청함(기간 끝까지 유지) | `SubEndCancel` — 마지막 줄이 `이용 종료일` | [해지 신청 취소] |
///
/// 📌 **구독 중에는 요금제 목록을 보여 주지 않는다** — `SubManage` 시안이 그 자리에 구독 정보를 둔다
/// (기획 확인 대기였던 것이 이 시안으로 풀렸다).
///
/// 시안은 **밝은 바탕**이다. 좌표는 전부 1080 캔버스 그대로 쓰고, 화면 전체를 [_PrimeCanvas]가
/// 한 번에 줄인다 — 그래서 이 파일의 숫자는 시안 `*좌표값.png`의 숫자와 같다.
class PrimeScreen extends ConsumerStatefulWidget {
  const PrimeScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const PrimeScreen());

  @override
  ConsumerState<PrimeScreen> createState() => _PrimeScreenState();
}

const _dir = 'assets/images/scene_shop/prime_sub';

/// 시안에서 뽑은 색(참고화면 픽셀).
const _ink = Color(0xFF191919); // 혜택 제목
const _inkSoft = Color(0xFF4B4A4A); // 혜택 설명
const _section = Color(0xFF22272D); // `요금제 선택하기` · `PRIME 혜택`
const _label = Color(0xFF686C77); // 구독 정보 왼쪽 칸
const _notice = Color(0xFF202027); // 아래 안내 두 줄
const _pillOn = Color(0xFF4108FD); // 고른 카드의 가격
const _pillOff = Color(0xFF3A3D44); // 안 고른 카드의 가격

class _PrimeScreenState extends ConsumerState<PrimeScreen> {
  String? _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // 구독은 기간이 끝나면 저절로 바뀐다 — 들어올 때마다 다시 읽는다(클라 갱신 방침).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(walletProvider.notifier).refresh();
    });
  }

  Future<void> _subscribe(PrimePlan plan) async {
    final l10n = L10n.of(context);
    setState(() => _busy = true);
    // 스토어 결제창이 붙기 전까지는 개발용 토큰으로 서버 검증을 태운다(01 §1.8 ①, 막힌 것 E).
    final error = await ref.read(storeActionsProvider).verifyPurchase(
      productId: plan.productId,
      purchaseToken: 'dev-${plan.productId}-${DateTime.now().millisecondsSinceEpoch}',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(error == null ? l10n.primeStarted : errorMessage(l10n, error));
  }

  /// [구독 관리] → 해지 팝업(`SubEnd`). [구독 해지]를 누르면 자동 갱신만 끈다 — 기간 끝까지 혜택은 그대로.
  Future<void> _openCancel(Wallet wallet) async {
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _CancelPopup(endDate: _date(wallet.subscriptionExpiresAt)),
    );
    if (confirmed != true || !mounted) return;
    final error = await ref.read(storeActionsProvider).cancelSubscription();
    if (!mounted) return;
    _toast(error == null ? l10n.primeCancelDone : errorMessage(l10n, error));
  }

  Future<void> _resume() async {
    final l10n = L10n.of(context);
    setState(() => _busy = true);
    final error = await ref.read(storeActionsProvider).resumeSubscription();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(error == null ? l10n.primeResumeDone : errorMessage(l10n, error));
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final wallet = ref.watch(walletProvider);
    final catalog = ref.watch(catalogProvider);
    final plans = catalog.valueOrNull?.primePlans ?? const <PrimePlan>[];

    Widget body;
    if (wallet.valueOrNull == null || catalog.valueOrNull == null) {
      final failed = wallet.hasError || catalog.hasError;
      body = Center(
        child: failed
            ? Text(l10n.storeLoadFailed, style: const TextStyle(color: _label))
            : const CircularProgressIndicator(color: _pillOn),
      );
    } else {
      final w = wallet.value!;
      body = _PrimeCanvas(
        top: (y) => [
          ..._header(context, y),
          if (!w.prime)
            ..._planPicker(l10n, plans, y)
          else
            ..._subscriptionInfo(l10n, w, y),
          ..._benefits(l10n, plans, y),
        ],
        noticeText: !w.prime
            ? l10n.primeSubscriptionNotice
            : w.autoRenew
                ? l10n.primeManageNotice
                : l10n.primeCanceledNotice(_date(w.subscriptionExpiresAt)),
        button: !w.prime
            ? _buyButton(l10n, plans)
            : w.autoRenew
                ? _ArtButton(
                    asset: '$_dir/sub_manage/button_primemanagement.png',
                    width: 940,
                    height: 138,
                    left: 67,
                    onTap: () => _openCancel(w),
                  )
                : _ArtButton(
                    asset: '$_dir/sub_end_cancel/button_subkeep.png',
                    width: 934,
                    height: 139,
                    left: 67,
                    onTap: _busy ? null : _resume,
                  ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(backgroundColor: Colors.white, body: body),
    );
  }

  // ── 위쪽: 타이틀 · 닫기 · 배너 ──

  List<Widget> _header(BuildContext context, _Y y) {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    return [
      // 타이틀은 언어마다 폭이 달라 시작점도 다르다(시안 `kr : 308 / jp : 268`).
      Positioned(
        left: ja ? 268 : 308,
        top: y(147),
        child: const ArtImage('$_dir/sub_start/title_prime.png',
            width: 450, height: 69, scale: 1),
      ),
      // ⚠️ `SubManage`·`SubEndCancel` 시안엔 [X]가 없다. 나갈 길이 시스템 뒤로가기뿐이면
      //    iOS·제스처 사용자가 막히므로 같은 그림을 같은 자리에 둔다(보고 · 10 미결).
      Positioned(
          left: 928 - 20,
          top: y(133) - 20,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(20), // 손가락 자리 — 그림(94)보다 넓게
              child: ArtImage('$_dir/sub_start/button_primeexit.png',
                  width: 94, height: 94, scale: 1),
            ),
          ),
        ),
      Positioned(
        left: 52,
        top: y(249),
        child: ArtImage('$_dir/sub_start/back_primebanner.png',
            width: 978, height: 252, scale: 1),
      ),
    ];
  }

  // ── 구독 전: 요금제 카드 ──

  List<Widget> _planPicker(L10n l10n, List<PrimePlan> plans, _Y y) {
    final cards = plans.where((p) => _cardAsset(p, true) != null).toList();
    final selected = _selectedPlan(plans);
    return [
      _SectionTitle(l10n.primePlanSection, top: y(562)),
      Positioned(
        left: 0,
        right: 0,
        top: y(637),
        height: 456,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 52),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: 783 - 52 - 681),
          itemBuilder: (_, i) {
            final plan = cards[i];
            final on = plan.productId == selected?.productId;
            return GestureDetector(
              onTap: () => setState(() => _selected = plan.productId),
              child: SizedBox(
                width: 681,
                height: 456,
                child: Stack(
                  children: [
                    ArtImage(_cardAsset(plan, on)!,
                        width: 681, height: 456, scale: 1),
                    // 가격 알약 자리(카드 그림 안 84~603 × 303~416). 숫자는 폰트가 그린다.
                    Positioned(
                      left: 84,
                      top: 303,
                      width: 603 - 84,
                      height: 416 - 303,
                      child: Center(
                        child: Text(
                          l10n.primeMonthlyPrice(_won(_monthly(plan))),
                          style: TextStyle(
                            color: on ? _pillOn : _pillOff,
                            fontSize: 69,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  PrimePlan? _selectedPlan(List<PrimePlan> plans) {
    for (final p in plans) {
      if (p.productId == _selected) return p;
    }
    // 처음엔 `인기`(1개월)가 골라져 있다(시안).
    for (final p in plans) {
      if (p.months == 1) return p;
    }
    return plans.isEmpty ? null : plans.first;
  }

  /// 1개월·6개월 카드 그림. 그 밖의 플랜은 그림이 없어 그리지 않는다.
  String? _cardAsset(PrimePlan plan, bool on) => switch (plan.months) {
    1 => '$_dir/sub_start/button_1month${on ? 'color' : 'normal'}.png',
    6 => '$_dir/sub_start/button_6month${on ? 'color' : 'normal'}.png',
    _ => null,
  };

  /// 알약은 `월 ○원` — 6개월은 한 달 값으로 나눠 보인다(20% 할인이 바로 보이게).
  int _monthly(PrimePlan plan) =>
      plan.months <= 1 ? plan.price : (plan.price / plan.months).round();

  _ArtButton _buyButton(L10n l10n, List<PrimePlan> plans) {
    final plan = _selectedPlan(plans);
    return _ArtButton(
      asset: '$_dir/sub_start/button_primebuy.png',
      width: 940,
      height: 138,
      left: 67,
      onTap: plan == null || _busy ? null : () => _subscribe(plan),
      // `구매하기`는 그림, 금액은 폰트 — 그림 글자 오른쪽(시안 x 540)부터.
      overlay: plan == null
          ? null
          : Positioned(
              left: 540 - 67,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  l10n.primeBuyPrice(_won(plan.price)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 70,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
    );
  }

  // ── 구독 중: 구독 정보 ──

  List<Widget> _subscriptionInfo(L10n l10n, Wallet w, _Y y) {
    final months = switch (w.subscriptionProduct) {
      'PRIME_6M' => 6,
      _ => 1,
    };
    PrimePlan? plan;
    for (final p in ref.read(catalogProvider).valueOrNull?.primePlans ?? const <PrimePlan>[]) {
      if (p.product == w.subscriptionProduct) plan = p;
    }
    final rows = <(String, String)>[
      (l10n.primeInfoPrice, plan == null ? '-' : l10n.primeMonthlyPrice(_won(_monthly(plan)))),
      (l10n.primeInfoStart, _date(w.subscriptionStartedAt)),
      // 해지 신청 뒤엔 다음 결제가 없다 — 같은 날짜가 `이용 종료일`이 된다(시안 SubEndCancel).
      (w.autoRenew ? l10n.primeInfoNextBilling : l10n.primeInfoEndDate,
          _date(w.subscriptionExpiresAt)),
    ];
    const rowTops = [809.0, 904.0, 997.0];

    return [
      _SectionTitle(l10n.primeSubInfoSection, top: y(562)),
      Positioned(
        left: 52,
        top: y(642),
        child: ArtImage('$_dir/sub_manage/frame_primesubinfo.png',
            width: 975, height: 437, scale: 1),
      ),
      Positioned(
        left: 100,
        top: y(686) - 6,
        child: Text(
          l10n.primeProductName(months),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 60,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
      // 해지 신청 뒤에도 기간 끝까지는 `이용 중`이다(시안 SubEndCancel도 같은 표시).
      Positioned(
        left: 738,
        top: y(681),
        child: ArtImage('$_dir/sub_manage/icon_primeuse.png',
            width: 233, height: 74, scale: 1),
      ),
      for (var i = 0; i < rows.length; i++) ...[
        Positioned(
          left: 100,
          top: y(rowTops[i]) - 4,
          child: Text(
            rows[i].$1,
            style: const TextStyle(
              color: _label,
              fontSize: 44,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
        Positioned(
          right: 1080 - 975,
          top: y(rowTops[i]) - 4,
          child: Text(
            rows[i].$2,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 46,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
    ];
  }

  // ── PRIME 혜택(세 상태 공통) ──

  List<Widget> _benefits(L10n l10n, List<PrimePlan> plans, _Y y) {
    var boosts = 10;
    for (final p in plans) {
      if (p.months == 1) boosts = p.boosts['POST_BOOST'] ?? boosts;
    }
    // 기획서 10-1 혜택표 · 시안 다섯 줄. 광고 제거는 **광고 자체가 아직 없다**.
    final items = <(String, String)>[
      (l10n.primeBenefitAlbum, l10n.primeBenefitAlbumDesc),
      (l10n.primeBenefitBoost(boosts), l10n.primeBenefitBoostDesc),
      (l10n.primeBenefitChat, l10n.primeBenefitChatDesc),
      (l10n.primeBenefitTranslate, l10n.primeBenefitTranslateDesc),
      (l10n.primeBenefitNoAds, l10n.primeBenefitNoAdsDesc),
    ];
    return [
      _SectionTitle(l10n.primeBenefitsSection, top: y(1153)),
      Positioned(
        left: 52,
        top: y(1230),
        child: ArtImage('$_dir/sub_start/frame_primeinfo.png',
            width: 975, height: 905, scale: 1),
      ),
      Positioned(
        left: 52,
        top: y(1230),
        width: 975,
        height: 905,
        // 일본어 설명이 길어 줄이 늘어도 틀 밖으로 나가지 않게 — 넘치면 통째로 조금 줄인다.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(51, 46, 16, 46),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 975 - 51 - 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 50),
                    _BenefitRow(title: items[i].$1, description: items[i].$2),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

/// 시안 y → 화면에 놓을 y. 세로가 모자란 기기에서 빈 띠를 줄인 만큼 당겨 준다.
typedef _Y = double Function(double designY);

/// 시안 캔버스(1080 폭)를 그대로 그리고 화면에 맞춘다.
///
/// 시안은 1080×2640(약 2.44:1)인데 흔한 폰은 20:9(2.22:1)라 세로가 모자란다. 그래서
/// - 아래 안내·버튼은 **화면 바닥 기준**으로 붙인다(시안 아래 여백 190은 긴 화면 값 — 짧으면 줄인다).
/// - 그래도 혜택 틀과 겹치면 **빈 띠부터 줄인다** — 타이틀 위(상태바 바로 아래까지),
///   그다음 배너 아래·카드 아래 두 틈(각 45까지). 위쪽 좌표는 [top]이 받는 `y()`로 이 몫을 반영한다.
/// - 그래도 모자라면 마지막으로 **전체를 같은 비율로 줄인다**(좌우에 여백이 생긴다).
///
/// 고정 화면이라 스크롤하지 않는다(콘텐츠 공통 결정).
class _PrimeCanvas extends StatelessWidget {
  const _PrimeCanvas({
    required this.top,
    required this.noticeText,
    required this.button,
  });

  final List<Widget> Function(_Y y) top;
  final String noticeText;
  final _ArtButton button;

  static const double _frameBottom = 1230 + 905; // 혜택 틀 아랫변
  static const double _frameToNotice = 24; // 시안은 57 — 모자랄 때 남기는 최소
  static const double _noticeToButton = 2312 - 2192;
  static const double _designBottomGap = 2640 - 2450;
  static const double _topmost = 133; // [X] 윗변 — 가장 위에 있는 것
  static const double _gapMax = 45; // 배너 아래·카드 아래 틈을 줄일 수 있는 한도(각각, 시안 61·60)

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final s = c.maxWidth / DesignCanvas.width;
        final h = c.maxHeight / s;
        final statusBar = mq.padding.top / s;
        final nav = mq.padding.bottom / s;
        final bottomGap = (_designBottomGap - (DesignCanvas.height - h))
            .clamp(nav + 32, _designBottomGap)
            .toDouble();
        var short = math.max(
            0.0,
            _frameBottom + _frameToNotice + _noticeToButton + button.height +
                bottomGap - h);
        final shift = math.min(short, math.max(0.0, _topmost - statusBar - 16));
        short -= shift;
        final gapA = math.min(short / 2, _gapMax);
        final gapB = math.min(short - gapA, _gapMax);
        short -= gapA + gapB;
        double y(double v) =>
            v - shift - (v >= 562 ? gapA : 0) - (v >= 1153 ? gapB : 0);

        final canvasH = h + short;
        final buttonTop = canvasH - bottomGap - button.height;

        return MediaQuery.withNoTextScaling(
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: DesignCanvas.width,
              height: canvasH,
              child: Stack(
                children: [
                  ...top(y),
                  Positioned(
                    left: 60,
                    right: 60,
                    top: buttonTop - _noticeToButton,
                    child: Text(
                      noticeText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _notice,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Positioned(left: button.left, top: buttonTop, child: button),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.top});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 65,
      top: top - 4,
      child: Text(
        text,
        style: const TextStyle(
          color: _section,
          fontSize: 54,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 체크는 제목과 설명 첫 줄 사이 가운데에 온다(시안).
        const Padding(
          padding: EdgeInsets.only(top: 26),
          child: ArtImage('$_dir/sub_start/icon_primecheck.png',
              width: 56, height: 45, scale: 1),
        ),
        const SizedBox(width: 203 - 103 - 56),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 50,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: _inkSoft,
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 글자가 구워진 그림 버튼. 금액처럼 변하는 값은 [overlay]로 얹는다.
class _ArtButton extends StatelessWidget {
  const _ArtButton({
    required this.asset,
    required this.width,
    required this.height,
    required this.left,
    required this.onTap,
    this.overlay,
  });

  final String asset;
  final double width;
  final double height;
  final double left;
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

/// 해지 팝업(시안 `SubEnd`). [구독 해지] → true, [아니요]·바깥 → false.
class _CancelPopup extends StatelessWidget {
  const _CancelPopup({required this.endDate});

  final String endDate;

  static const double _w = 993;
  static const double _h = 1218;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = MediaQuery.sizeOf(context).width / DesignCanvas.width;
    // 시안 좌표는 화면 기준이라 팝업 왼쪽 위(51, 863)를 빼서 쓴다.
    double x(double v) => v - 51;
    double y(double v) => v - 863;

    return Center(
      child: MediaQuery.withNoTextScaling(
        child: SizedBox(
          width: _w * s,
          height: _h * s,
          child: FittedBox(
            child: SizedBox(
              width: _w,
              height: _h,
              child: Material(
                type: MaterialType.transparency,
                child: Stack(
                  children: [
                    const ArtImage('$_dir/sub_end/frame_subcandelpopup.png',
                        width: _w, height: _h, scale: 1),
                    Positioned(
                      left: x(454),
                      top: y(916),
                      child: const ArtImage('$_dir/sub_end/icon_notice.png',
                          width: 164, height: 164, scale: 1),
                    ),
                    Positioned(
                      left: 30,
                      right: 30,
                      top: y(1147) - 6,
                      child: Text(
                        l10n.primeCancelTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 62,
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
                        l10n.primeCancelBody(endDate),
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
                      child: _ArtButton(
                        asset: '$_dir/sub_end/button_subcancel.png',
                        width: 808,
                        height: 139,
                        left: 0,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                    Positioned(
                      left: x(136),
                      top: y(1864),
                      child: _ArtButton(
                        asset: '$_dir/sub_end/button_cancel.png',
                        width: 808,
                        height: 139,
                        left: 0,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
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

/// `2026.10.22` — 시안의 날짜 표기.
String _date(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  return '${local.year}.${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')}';
}

/// `12,900` — 세 자리마다 쉼표.
String _won(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
