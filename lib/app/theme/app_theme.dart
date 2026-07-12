import 'package:flutter/material.dart';

/// 야간 컨셉 다크 테마의 골격.
///
/// 색상·타이포 토큰(달빛/밤 컨셉)은 디자인 확정 시 채운다.
/// 앱은 다크 모드 고정으로 시작한다.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(),
      );
}
