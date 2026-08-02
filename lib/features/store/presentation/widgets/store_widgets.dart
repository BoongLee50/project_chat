import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';

/// 상점 화면들이 공유하는 조각들.
///
/// 시안(기획서 25~30)은 라이트 테마지만 앱은 **다크 고정**이라 톤만 맞춰 옮겼다.
/// 구성·문구·가격 위계는 시안 그대로다. (프로필 화면과 같은 판단 — 04 문서 미결 #4)

/// 상단 타이틀 + 부제 + 닫기(X). 시안의 헤더 형태.
class StoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StoreAppBar({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor = AppColors.moonlight,
    this.showClose = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final bool showClose;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 64 : 84);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.night,
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: AppDimens.pagePad,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (showClose)
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// 보유 루나 배너. 시안 25·27 상단.
class LunaBalanceCard extends StatelessWidget {
  const LunaBalanceCard({super.key, required this.luna, this.onCharge});

  final int luna;
  final VoidCallback? onCharge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.moonlight.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Text(
            '보유 루나',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.star_rounded, color: AppColors.gold, size: 26),
          const SizedBox(width: 6),
          Text(
            '$luna',
            style: const TextStyle(
              color: AppColors.moonlight,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (onCharge != null)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.moonlight,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: onCharge,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('충전하기'),
            ),
        ],
      ),
    );
  }
}

/// 가격 한 줄 — "1시간, 5매 · ⭐ 400". 선택형이면 [selected]로 강조한다.
class PriceOptionTile extends StatelessWidget {
  const PriceOptionTile({
    super.key,
    required this.label,
    required this.price,
    required this.onTap,
    this.selected = false,
    this.badge,
    this.accent = AppColors.moonlight,
  });

  final String label;
  final int price;
  final VoidCallback onTap;
  final bool selected;
  final String? badge;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.16)
                    : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                  color: selected ? accent : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$price',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              left: 10,
              top: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 혜택 한 줄(아이콘 + 제목 + 설명 + 체크). 시안 26·29·30 공통.
class BenefitRow extends StatelessWidget {
  const BenefitRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.accent = AppColors.moonlight,
    this.checked = true,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (checked) ...[
            const SizedBox(width: 10),
            Icon(Icons.check_circle_outline, color: accent, size: 22),
          ],
        ],
      ),
    );
  }
}

/// 섹션 카드 껍데기.
class StoreCard extends StatelessWidget {
  const StoreCard({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color? accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(
          color: accent?.withValues(alpha: 0.5) ?? AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

/// "구매 금액 / 구매일 / 유효 기간" 같은 정보 줄. 시안 29·30 이용 정보.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 하단 고정 액션 버튼.
class StoreBottomButton extends StatelessWidget {
  const StoreBottomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.moonlight,
    this.icon,
    this.price,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final int? price;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppDimens.pagePad,
        0,
        AppDimens.pagePad,
        AppDimens.gapMd,
      ),
      child: SizedBox(
        height: 54,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: AppColors.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
          onPressed: busy ? null : onPressed,
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (price != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$price',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
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

/// 상태 배지 — "구매 대기" / "현재 적용 중" / "사용 중".
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color = AppColors.moonlight,
    this.filled = true,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
