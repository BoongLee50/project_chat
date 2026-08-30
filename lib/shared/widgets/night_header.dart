import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../features/store/presentation/providers/store_provider.dart';
import '../../features/store/presentation/screens/luna_store_screen.dart';
import '../../features/store/presentation/screens/prime_screen.dart';

/// 대화방·친구 목록 상단의 밤 풍경 머리글(기획 6-1 · 7-1).
///
/// 시안은 세 화면이 **같은 머리글**을 쓴다 — 제목과 부제, 오른쪽에 `[VIP]`와 `[★ 루나]`.
/// 화면마다 따로 그리면 하나만 손보게 되므로 여기 한 곳에 둔다.
///
/// **배경 그림은 아직 없다.** 기획이 리소스를 따로 주기로 했으므로(docs/08 §0)
/// 그림을 만들어 채우지 않고 밤하늘 그러데이션으로 자리를 잡아 둔다 —
/// 그림이 오면 [backgroundAsset]만 채우면 된다.
class NightHeader extends ConsumerWidget {
  const NightHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showDot = true,
    this.trailing,
    this.backgroundAsset,
    this.child,
  });

  final String title;
  final String? subtitle;

  /// 제목 옆 보라색 점(시안). 새 소식 표시가 아니라 장식이다.
  final bool showDot;

  /// 오른쪽 위 자리. 비우면 [VIP]/[★ 루나] 기본 조합이 들어간다.
  final Widget? trailing;

  /// 밤 풍경 배경. 리소스가 오면 여기에 경로를 넣는다.
  final String? backgroundAsset;

  /// 머리글 아래에 겹쳐 놓을 것(탭 줄 등).
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned.fill(
          child: backgroundAsset == null
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1B1636), AppColors.night],
                    ),
                  ),
                )
              : Image.asset(backgroundAsset!, fit: BoxFit.cover),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gapMd,
            AppDimens.gapMd,
            AppDimens.gapMd,
            AppDimens.gapSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (showDot) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.moonlight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const Spacer(),
                  trailing ?? const HeaderPills(),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              if (child != null) ...[
                const SizedBox(height: AppDimens.gapMd),
                child!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// `[👑 VIP]` `[★ 80]` — 프라임 여부와 보유 루나.
///
/// 프라임이 아니면 같은 자리에 **가입 유도**가 들어간다. 시안의 VIP 배지는
/// 이미 프라임인 사람의 화면이라 그대로 두면 비프라임에게 빈자리가 생긴다.
class HeaderPills extends ConsumerWidget {
  const HeaderPills({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider).valueOrNull;
    final prime = wallet?.prime ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pill(
          icon: prime ? Icons.workspace_premium_rounded : Icons.auto_awesome,
          label: prime ? 'VIP' : 'Prime',
          color: prime ? AppColors.gold : AppColors.moonlight,
          onTap: () => Navigator.of(context).push(PrimeScreen.route()),
        ),
        const SizedBox(width: 6),
        _Pill(
          icon: Icons.star_rounded,
          label: '${wallet?.luna ?? 0}',
          color: AppColors.gold,
          onTap: () => Navigator.of(context).push(LunaStoreScreen.route()),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `[💬 대화 2]` `[✉ 받은 신청 2]` 같은 알약 탭 줄(기획 6-1 · 7-1).
class PillTabs extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<PillTab> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _TabButton(
              tab: tabs[i],
              selected: i == index,
              onTap: () => onChanged(i),
            ),
          ),
        ],
      ],
    );
  }
}

class PillTab {
  const PillTab({required this.icon, required this.label, this.count = 0});

  final IconData icon;
  final String label;

  /// 0이면 숫자를 그리지 않는다 — 시안의 배지는 있을 때만 있다.
  final int count;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final PillTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.moonlight.withValues(alpha: 0.18)
              : AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.moonlight : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: 16,
              color: selected ? AppColors.moonlight : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                tab.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (tab.count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.moonlight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tab.count}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
