import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/daily_provider.dart';
import 'daily_list_screen.dart';

/// 달빛 한마디 [타이틀] 화면(기획 8-1) — 오늘의 질문 · 참여 인원 · 남은 시간 · [참여하기].
///
/// 달빛가든 필터 줄의 네 번째 칸에서 들어온다.
class DailyIntroScreen extends ConsumerStatefulWidget {
  const DailyIntroScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const DailyIntroScreen());

  @override
  ConsumerState<DailyIntroScreen> createState() => _DailyIntroScreenState();
}

class _DailyIntroScreenState extends ConsumerState<DailyIntroScreen> {
  Timer? _ticker;

  /// 서버가 준 남은 초에서 1초씩 깎는다.
  ///
  /// **기기 시계로 18시까지를 직접 계산하지 않는다** — 시계가 틀어진 기기에서
  /// 사람마다 다른 시간이 보이기 때문이다. 기준은 서버가 주고 흐르게만 한다.
  int? _remaining;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _remaining;
      if (left != null && left > 0) setState(() => _remaining = left - 1);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _hms(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
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

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.dailyTitle),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: today.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (error, _) => Center(
          child: Text(
            l10n.dailyLoadFailed,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        data: (data) => Padding(
          padding: const EdgeInsets.all(AppDimens.pagePad),
          child: Column(
            children: [
              _Pill(text: l10n.dailyMissionNotice),
              const SizedBox(height: AppDimens.gapLg),
              Text(
                l10n.dailyTodayQuestion,
                style: const TextStyle(
                  color: AppColors.moonlight,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimens.gapMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.pagePad),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(color: AppColors.moonlight),
                ),
                child: Text(
                  data.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.gapLg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.dailyParticipants(data.participants),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.dailyRemaining,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _hms(_remaining ?? data.remainingSeconds),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.gapMd),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacement(DailyListScreen.route()),
                  child: Text(l10n.dailyJoin),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 15,
            color: AppColors.moonlight,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
