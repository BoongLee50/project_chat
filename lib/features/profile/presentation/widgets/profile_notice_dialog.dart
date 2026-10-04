import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// 한도 안내 팝업 — 기획서 8-1의 *"…라는 안내 메시지 팝업을 출력"*.
///
/// 버튼을 죽이지 않고 **왜 안 되는지 말한다**(관심사 3개 · 지역 1곳 · 자기소개 300자).
/// 그림 리소스가 따로 오지 않아 [ConfirmDialog]와 같은 기본 모양에 [확인] 한 칸만 둔다.
Future<void> showProfileNotice(BuildContext context, String message) {
  final l10n = L10n.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            l10n.commonConfirm,
            style: const TextStyle(
              color: AppColors.moonlight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
