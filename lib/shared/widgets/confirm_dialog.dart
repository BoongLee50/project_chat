import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// 되돌리기 어려운 동작 전에 한 번 묻는 팝업. (Plan_4에서 삭제·공유에 추가됐다)
///
/// 시안(`오늘의 포스트 화면구성_메세지창.png`)은 **OS 기본 다이얼로그 모양**이다 —
/// 그림 리소스가 따로 오지 않았고 [취소]/[확인] 두 칸이라, 문구만 ARB로 받아 그린다.
///
/// 확인하면 `true`, 취소하거나 바깥을 누르면 `false`를 돌려준다.
class ConfirmDialog {
  const ConfirmDialog._();

  static Future<bool> show(BuildContext context, String message) async {
    final l10n = L10n.of(context);
    final ok = await showDialog<bool>(
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
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.commonCancel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
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
    return ok ?? false;
  }
}
