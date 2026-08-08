import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';


/// 사진을 어디서 가져올지 고른 결과.
enum PhotoSource { gallery, camera, remove }

/// 사진 버튼을 누르면 뜨는 선택 시트 — **포스트와 프로필이 함께 쓴다.**
///
/// 두 화면의 동작이 조금 다르다(프로필만 제거가 있고, 포스트는 앨범이 패스 전용).
/// 그래서 시트는 **무엇을 할지 고르기만** 하고, 실제 촬영·업로드·삭제는 부르는 쪽이 한다.
///
/// 시안은 밝은 배경이지만 달빛톡은 **다크 테마 고정**이라 그대로 쓰면 화면에서 튄다.
/// 구성(제목·설명·아이콘＋라벨＋꺾쇠 3줄)은 시안을 따르고 색만 앱 팔레트로 맞췄다.
class PhotoSourceSheet extends StatelessWidget {
  const PhotoSourceSheet._({
    required this.title,
    required this.subtitle,
    required this.galleryEnabled,
    required this.galleryHint,
    required this.showRemove,
    required this.removeEnabled,
  });

  final String title;
  final String subtitle;

  /// 앨범 선택 가능 여부. 포스트는 앨범 패스 보유자만이다(기획서 3-1).
  final bool galleryEnabled;

  /// 앨범이 막힌 이유. 막아만 두면 고장으로 보이니 줄 아래에 적어 준다.
  final String? galleryHint;

  final bool showRemove;
  final bool removeEnabled;

  /// 고른 값을 돌려준다. 닫기만 하면 null.
  static Future<PhotoSource?> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    bool galleryEnabled = true,
    String? galleryHint,
    bool showRemove = false,
    bool removeEnabled = false,
  }) => showModalBottomSheet<PhotoSource>(
    context: context,
    backgroundColor: AppColors.night,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => PhotoSourceSheet._(
      title: title,
      subtitle: subtitle,
      galleryEnabled: galleryEnabled,
      galleryHint: galleryHint,
      showRemove: showRemove,
      removeEnabled: removeEnabled,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 16),
            _Row(
              icon: Icons.photo_library_outlined,
              label: l10n.photoSourceGallery,
              hint: galleryEnabled ? null : galleryHint,
              enabled: galleryEnabled,
              onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
            ),
            const SizedBox(height: 10),
            _Row(
              icon: Icons.photo_camera_outlined,
              label: l10n.photoSourceCamera,
              enabled: true,
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
            if (showRemove) ...[
              const SizedBox(height: 10),
              _Row(
                icon: Icons.delete_outline,
                label: l10n.photoSourceRemove,
                enabled: removeEnabled,
                danger: true,
                onTap: () => Navigator.of(context).pop(PhotoSource.remove),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 시트의 한 줄. 아이콘 타일 + 라벨(+사유) + 꺾쇠.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.hint,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final bool enabled;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppColors.danger : AppColors.moonlight;
    // 못 쓰는 줄은 색을 죽여서 "지금은 안 된다"가 한눈에 보이게 한다.
    final iconColor = enabled ? accent : AppColors.textMuted;
    final labelColor = enabled ? AppColors.textPrimary : AppColors.textMuted;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          // 비활성이면 탭 자체를 막는다(null이면 잉크 효과도 안 난다).
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hint != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          hint!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: enabled ? AppColors.textSecondary : AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
