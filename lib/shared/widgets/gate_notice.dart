import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../features/auth/presentation/providers/gate_provider.dart';

/// 운영시간 밖 안내. 남은 시간을 1초마다 갱신한다.
///
/// 게이트는 기능마다 막히는 범위가 달라(가든은 전부, 포스트는 등록만, 대화방은
/// 매칭 대화만) 두 가지 모양을 쓴다 — 전체를 덮는 [GateClosedView]와
/// 화면 위에 얹는 [GateBanner].

/// 남은 시간을 세어 "3시간 12분" 형태로 돌려준다. 열려 있으면 null.
class _Countdown extends ConsumerStatefulWidget {
  const _Countdown({required this.builder});

  final Widget Function(BuildContext context, String? remaining) builder;

  @override
  ConsumerState<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends ConsumerState<_Countdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextOpen = ref.watch(gateProvider).valueOrNull?.nextOpenAt;
    if (nextOpen == null) return widget.builder(context, null);

    final left = nextOpen.difference(DateTime.now());
    if (left.isNegative) return widget.builder(context, null);

    final hours = left.inHours;
    final minutes = left.inMinutes % 60;
    final seconds = left.inSeconds % 60;
    final text = hours > 0
        ? '$hours시간 $minutes분'
        : (minutes > 0 ? '$minutes분 $seconds초' : '$seconds초');
    return widget.builder(context, text);
  }
}

/// 화면 전체를 덮는 안내. 달빛가든처럼 **기능 전체가 잠기는** 탭에 쓴다.
class GateClosedView extends StatelessWidget {
  const GateClosedView({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _Countdown(
      builder: (context, remaining) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.pagePad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.moonlight.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.nightlight_round,
                  color: AppColors.moonlight,
                  size: 46,
                ),
              ),
              const SizedBox(height: AppDimens.gapLg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              if (remaining != null) ...[
                const SizedBox(height: AppDimens.gapLg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.moonlight),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '문 열리기까지',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remaining,
                        style: const TextStyle(
                          color: AppColors.moonlight,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 화면 위에 얹는 한 줄 안내. 일부 동작만 잠기는 탭(포스트·대화방)에 쓴다.
class GateBanner extends StatelessWidget {
  const GateBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Countdown(
      builder: (context, remaining) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppDimens.gapMd),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.moonlight.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.moonlight.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.nightlight_round,
                color: AppColors.moonlight, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (remaining != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '$remaining 뒤에 열려요.',
                        style: const TextStyle(
                          color: AppColors.moonlight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
