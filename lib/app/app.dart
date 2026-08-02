import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// 앱 루트 위젯.
///
/// 상태관리는 Riverpod(main.dart의 ProviderScope), 라우팅은 go_router.
/// 진입 화면은 세션 상태에 따라 [routerProvider]가 결정한다.
///
/// 언어는 **기기 설정**을 따른다(한국어/일본어 지원, 그 외는 한국어).
/// 앱 안에서 직접 고르는 설정은 아직 없다 — 필요해지면 [locale]에 사용자 선택을
/// 주입하면 되도록 자리는 열어 두었다.
class DalbittokApp extends ConsumerWidget {
  const DalbittokApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => L10n.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      // 지원하지 않는 언어(영어 등)는 **한국어**로 떨어뜨린다.
      // 기본 동작은 supportedLocales의 첫 항목인데 그게 알파벳순이라 일본어라,
      // 영어 기기 사용자가 일본어를 보게 된다. 원문이 한국어이므로 여기서 못박는다.
      localeResolutionCallback: (locale, supported) {
        final code = locale?.languageCode;
        if (code != null && supported.any((l) => l.languageCode == code)) {
          return Locale(code);
        }
        return const Locale('ko');
      },
      routerConfig: ref.watch(routerProvider),
    );
  }
}
