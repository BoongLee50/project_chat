import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// 앱 전역 다크 테마.
///
/// 팔레트는 [AppColors], 치수는 [AppDimens]에 정의. 앱은 다크 모드 고정.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark => darkFor('ko');

  /// 언어별 테마 — **폰트만 다르다**(사용자 결정 2026-11-21: Noto Sans KR · Noto Sans JP).
  ///
  /// 한국어 화면은 `AppKo`(Noto Sans KR), 일본어 화면은 `AppJa`(Noto Sans JP). 서로를 대신 그릴 폰트로 걸어 두어
  /// 일본어 화면의 한국 사람 글(한글)·한국어 화면의 일본 사람 글(가나)도 같은 계열로 나온다.
  /// 한자는 화면 언어의 폰트가 먼저라 한국식·일본식 자형이 언어를 따른다.
  /// 🚨 글자 스타일(`TextStyle`)에 `fontFamily`를 직접 넣지 말 것 — 넣으면 그 자리만 언어 전환에서 빠진다.
  static ThemeData darkFor(String languageCode) {
    final ja = languageCode == 'ja';
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: ja ? 'AppJa' : 'AppKo',
      fontFamilyFallback: [ja ? 'AppKo' : 'AppJa'],
    );

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
