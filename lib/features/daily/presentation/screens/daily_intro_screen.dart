import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../providers/daily_provider.dart';
import '../widgets/daily_write_sheet.dart';
import '../widgets/word_art.dart';
import 'daily_list_screen.dart';

/// 달빛 한마디 [타이틀](기획서 261011 **9-1**) — 오늘의 질문 · 남은 시간 · [참여하기] · `<` 나가기.
///
/// 달빛가든 필터 줄의 네 번째 칸(`button_Moonlight`)에서 들어온다.
///
/// 흐름(261011에서 바뀌었다 — 260919/261002는 [참여하기] → 목록이었다):
/// - 🚪 **오늘 이미 등록했으면 타이틀을 건너뛰고 [답글 목록]을 바로 그린다** — 다음 질문(KST 18시)이
///   열리기 전까지 타이틀은 다시 안 나온다(2026-10-11 사용자 결정). 가든 입구는 그대로 이 화면을 연다.
///   그래서 오늘 상태는 들어올 때마다 **새로 읽는다**(`dailyTodayProvider`가 `autoDispose`).
/// - [참여하기] → **[내 한마디 등록] 시트가 아래에서 올라온다**(2026-10-11 사용자 결정).
///   등록해야 [답글 목록]이 열린다(기획 9-1).
/// - 시트의 `✕` → **애니메이션 없이 뚝 사라지고**, 쓰던 글·사진도 지워진다(같은 결정).
///   다시 열면 빈 시트다 — 시트는 닫힐 때 트리에서 빠져 상태가 남지 않는다.
/// - [등록하기] → [답글 목록]으로 바꿔 끼운다. 목록의 [나가기]는 가든으로 간다.
///
/// 그림 한 장(`back_friends`)에 머리·안내·빈 질문 카드가 구워져 있어 **배경과 같은 배율로** 얹는다
/// ([_Canvas]). 참여 인원은 261011에서 빠졌다.
class DailyIntroScreen extends ConsumerStatefulWidget {
  const DailyIntroScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const DailyIntroScreen());

  @override
  ConsumerState<DailyIntroScreen> createState() => _DailyIntroScreenState();
}

class _DailyIntroScreenState extends ConsumerState<DailyIntroScreen>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;

  /// 서버가 준 남은 초에서 1초씩 깎는다.
  ///
  /// **기기 시계로 18시까지를 직접 계산하지 않는다** — 시계가 틀어진 기기에서
  /// 사람마다 다른 시간이 보이기 때문이다. 기준은 서버가 주고 흐르게만 한다.
  int? _remaining;

  /// 시트가 올라오는 연출. 닫을 때는 **되감지 않고** 값을 0으로 떨어뜨린다(뚝 사라지게).
  late final AnimationController _sheet = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  bool _writing = false;
  bool _refreshed = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _remaining;
      if (left == null) return;
      if (left > 1) {
        setState(() => _remaining = left - 1);
      } else if (left == 1) {
        // 18시가 지났다 — 새 질문을 받아 온다(기획 9-1 "18시에 모든 정보 초기화").
        setState(() => _remaining = 0);
        ref.invalidate(dailyTodayProvider);
      }
    });
  }

  /// 들어올 때마다 오늘 상태·목록을 **첫 그림 전에** 새로 읽는다.
  ///
  /// 🚨 `autoDispose`만으로는 안 됐다(실기 확인) — Riverpod은 버릴 provider를 **다음 프레임에** 치우는데,
  /// 가든이 가만히 있으면 그 프레임이 곧 이 화면이 열리는 프레임이라 **옛 값("이미 답함")이 살아남았다.**
  /// `initState`에서는 `ref`를 못 써서(Riverpod이 상위 위젯을 찾는다) 첫 `didChangeDependencies`에서 한다.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_refreshed) return;
    _refreshed = true;
    ref.invalidate(dailyTodayProvider);
    ref.invalidate(dailyListProvider);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sheet.dispose();
    super.dispose();
  }

  /// 남은 시간은 **분까지만**(기획 9-1) — `05 : 48`.
  String _hm(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')} : ${m.toString().padLeft(2, '0')}';
  }

  void _join() {
    setState(() => _writing = true);
    _sheet.forward(from: 0);
  }

  /// `✕`·뒤로 가기 — 뚝 사라진다. 시트가 트리에서 빠지면서 쓰던 글·사진도 같이 버려진다.
  void _closeSheet() {
    _sheet.value = 0;
    setState(() => _writing = false);
  }

  void _registered() {
    ref.invalidate(dailyTodayProvider);
    Navigator.of(context).pushReplacement(DailyListScreen.route());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final today = ref.watch(dailyTodayProvider);

    // 새로 읽어 올 때마다 카운트다운 기준을 서버 값으로 다시 맞춘다.
    ref.listen(dailyTodayProvider, (_, next) {
      final value = next.valueOrNull;
      if (value != null) setState(() => _remaining = value.remainingSeconds);
    });

    final data = today.valueOrNull;

    // 새로 읽는 동안은 그림 없이 기다린다 — 이미 답한 사람에게 타이틀이 번쩍 보였다 사라지면 안 된다.
    if (today.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.night,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
      );
    }
    // 오늘 이미 답했다 → 타이틀 없이 바로 목록. [나가기]는 이 라우트를 닫아 가든으로 간다.
    if (data != null && data.answered && !_writing) {
      return const DailyListScreen();
    }
    final remaining = _remaining ?? data?.remainingSeconds;

    return PopScope(
      canPop: !_writing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _writing) _closeSheet();
      },
      child: Scaffold(
        backgroundColor: AppColors.night,
        // 키보드는 시트가 직접 피한다([DailyWriteSheet]) — 배경까지 밀려 올라가면 그림이 찌그러진다.
        resizeToAvoidBottomInset: false,
        body: LayoutBuilder(
          builder: (context, box) {
            final c = _Canvas(box.biggest);
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    DesignCanvas.localizedAsset(context, WordArt.titleBack),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                // 오늘의 질문 — 구워진 카드의 점선 칸에 같은 기울기로 얹는다.
                Positioned(
                  left: c.x(
                    WordArt.questionCenter.dx - WordArt.questionBox.width / 2,
                  ),
                  top: c.y(
                    WordArt.questionCenter.dy - WordArt.questionBox.height / 2,
                  ),
                  width: WordArt.questionBox.width * c.s,
                  height: WordArt.questionBox.height * c.s,
                  child: Transform.rotate(
                    angle: WordArt.questionAngle,
                    child: Center(
                      child: today.when(
                        loading: () => const CircularProgressIndicator(
                          color: AppColors.moonlight,
                        ),
                        error: (_, _) => Text(
                          l10n.dailyLoadFailed,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: WordArt.ink,
                            fontSize: 36 * c.s,
                          ),
                        ),
                        data: (d) => Text(
                          d.question,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: WordArt.ink,
                            fontSize: 46 * c.s,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 남은 시간 · [참여하기] — 화면 아래에 붙는다(세로가 짧은 폰에서도 잘리지 않게).
                if (remaining != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: c.fromBottom(WordArt.clockTop),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ArtImage(
                          WordArt.clock,
                          width: WordArt.clockSize.width,
                          height: WordArt.clockSize.height,
                          scale: c.s,
                        ),
                        SizedBox(width: 18 * c.s),
                        Text(
                          '${l10n.dailyRemaining} ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42 * c.s,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _hm(remaining),
                          style: TextStyle(
                            color: WordArt.gold,
                            fontSize: 42 * c.s,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  left: c.x(WordArt.joinAt.dx),
                  top: c.fromBottom(WordArt.joinAt.dy),
                  child: Semantics(
                    button: true,
                    label: l10n.dailyJoin,
                    child: GestureDetector(
                      onTap: data == null ? null : _join,
                      child: ArtImage(
                        WordArt.join,
                        width: WordArt.joinSize.width,
                        height: WordArt.joinSize.height,
                        scale: c.s,
                      ),
                    ),
                  ),
                ),
                if (_writing)
                  AnimatedBuilder(
                    animation: _sheet,
                    builder: (context, child) {
                      final t = Curves.easeOutCubic.transform(_sheet.value);
                      return Transform.translate(
                        offset: Offset(0, (1 - t) * box.maxHeight),
                        child: child,
                      );
                    },
                    child: DailyWriteSheet(
                      canvasScale: c.s,
                      canvasLeft: c.x(0),
                      screen: box.biggest,
                      question: data?.question ?? '',
                      onClose: _closeSheet,
                      onRegistered: _registered,
                    ),
                  ),
                // `<` 나가기 — 시트가 떠 있어도 보이는 자리라(시안) 맨 위에 둔다. 누르면 가든으로.
                Positioned(
                  left: c.x(WordArt.exitMoonAt.dx),
                  top: c.y(WordArt.exitMoonAt.dy),
                  child: Semantics(
                    button: true,
                    label: l10n.commonBack,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: EdgeInsets.all(12 * c.s),
                        child: ArtImage(
                          WordArt.exitMoon,
                          width: WordArt.exitMoonSize.width,
                          height: WordArt.exitMoonSize.height,
                          scale: c.s,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 배경(1080×2640)을 **화면을 덮게** 늘렸을 때의 좌표 변환.
///
/// 배경은 위에 붙여 그린다 — 머리·질문 카드가 구워져 있어 그 자리가 움직이면 안 된다.
/// 세로가 짧은 폰(대부분)에서는 배경 아래쪽이 잘리므로, 남은 시간·[참여하기]는 **화면 아래 기준**으로
/// 같은 거리를 두고 놓는다([fromBottom]). 세로가 시안보다 긴 폰은 높이에 맞춰 늘리고 양옆이 잘린다.
class _Canvas {
  _Canvas(this.screen)
    : s = math.max(
        screen.width / DesignCanvas.width,
        screen.height / DesignCanvas.height,
      );

  final Size screen;
  final double s;

  double x(double designX) =>
      (screen.width - DesignCanvas.width * s) / 2 + designX * s;
  double y(double designY) => designY * s;

  /// 시안에서 캔버스 아래까지 남은 거리를 화면 아래에서 그대로 잰다.
  double fromBottom(double designY) =>
      screen.height - (DesignCanvas.height - designY) * s;
}
