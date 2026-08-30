import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/garden/data/models/translate_access.dart';
import '../../features/store/data/models/store_models.dart';
import '../../features/store/presentation/screens/pass_screen.dart';
import '../../l10n/app_localizations.dart';

/// `[⭐ 번역 | …]` — 댓글창 · 달빛 한마디 · 채팅창이 함께 쓰는 버튼(기획 4-2 · 5 · 8-3).
///
/// 기획서: *"[번역] 버튼 클릭 시 [자동번역 패스] 관리 화면 호출.
/// 무료 적용 및 구매 전과 후에 따라 **버튼 명칭 변경**.
/// 구매 후 남은 시간 표시는 **일, 시간, 분**으로 변경하여 출력."*
///
/// 오른쪽 칸에 들어가는 말이 상태를 그대로 드러낸다.
/// - 패스·프라임 → `3일 4시간` (남은 시간)
/// - 무료가 남음 → `무료 3회`
/// - 다 씀 → `구매`
/// - 공급자가 아직 없음 → `준비 중`
///
/// 🚨 **여기 있는 숫자는 하나도 이 파일이 정하지 않는다.** 전부 [access]가 들고 온다 —
/// 무료가 5회인지 3회인지, 패스가 며칠 남았는지는 서버 설정이다.
class TranslatePassButton extends StatelessWidget {
  const TranslatePassButton({super.key, required this.access, this.compact = false});

  final TranslateAccess? access;

  /// 채팅창 상단 바처럼 좁은 자리에서 쓰는 작은 모양.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final state = access;

    // 아직 못 받았으면 자리만 지킨다 — 잘못된 상태를 잠깐 보여 주는 것보다 낫다.
    if (state == null) return const SizedBox.shrink();

    final (label, active) = _describe(l10n, state);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context)
          .push(PassScreen.route(StoreKind.translatePass)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColors.gold : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: compact ? 13 : 14,
              color: active ? AppColors.gold : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.chatTranslatePass,
              style: TextStyle(
                color: active ? AppColors.gold : AppColors.textSecondary,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            Container(width: 1, height: compact ? 10 : 11, color: AppColors.border),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.gold : AppColors.textSecondary,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 오른쪽 칸의 말과 강조 여부.
  static (String, bool) _describe(L10n l10n, TranslateAccess a) {
    if (!a.providerReady) return (l10n.translateNotReady, false);
    if (a.unlimited) {
      final minutes = a.expiresInMinutes;
      // 프라임은 만료 시각이 없다 — 구독이 곧 기간이라 "무제한"이 정확하다.
      return minutes == null
          ? (l10n.chatTranslateUnlimited, true)
          : (_remaining(l10n, minutes), true);
    }
    if (a.remaining > 0) return (l10n.translateFreeLeft(a.remaining), true);
    return (l10n.homeBuy, false);
  }

  /// 남은 시간을 **일·시간·분**으로(시안 4-2). 큰 단위 둘까지만 보여 준다 —
  /// "3일 4시간 12분"은 읽히지 않고, 정확도가 필요한 값도 아니다.
  static String _remaining(L10n l10n, int minutes) {
    final days = minutes ~/ (60 * 24);
    final hours = (minutes % (60 * 24)) ~/ 60;
    if (days > 0) {
      return hours > 0
          ? '${l10n.homePassRemainingDays(days)} ${l10n.translateHours(hours)}'
          : l10n.homePassRemainingDays(days);
    }
    if (hours > 0) return l10n.translateHours(hours);
    return l10n.homeBoostRemaining(minutes);
  }
}
