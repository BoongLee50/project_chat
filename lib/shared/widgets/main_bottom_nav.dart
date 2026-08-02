import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../l10n/app_localizations.dart';

/// 메인 5탭 하단 내비게이션 (포스트·달빛가든·대화방·친구·프로필).
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.selected, required this.onTap});

  final int selected;
  final ValueChanged<int> onTap;

  /// 아이콘은 고정, 라벨은 언어에 따라 달라져 const로 둘 수 없다.
  static const _icons = <IconData>[
    Icons.photo_camera_rounded,
    Icons.nightlight_round,
    Icons.chat_bubble_outline,
    Icons.people_outline,
    Icons.person_outline,
  ];

  static List<String> _labels(L10n l10n) => [
    l10n.navPost,
    l10n.navGarden,
    l10n.navChat,
    l10n.navFriend,
    l10n.navProfile,
  ];

  @override
  Widget build(BuildContext context) {
    final labels = _labels(L10n.of(context));
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.night,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < _icons.length; i++)
            _NavItem(
              icon: _icons[i],
              label: labels[i],
              active: i == selected,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
