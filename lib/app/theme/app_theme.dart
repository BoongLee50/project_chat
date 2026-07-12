import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// 앱 전역 다크 테마.
///
/// 팔레트는 [AppColors], 치수는 [AppDimens]에 정의. 앱은 다크 모드 고정.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    final scheme = base.colorScheme.copyWith(
      primary: AppColors.moonlight,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: const Color(0xFF2A2400),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.night,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
