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
/// 언어는 **기기 설정**을 따른다(한국어/일본어 지원, **그 외는 일본어** — 사용자 결정 2026-11-21).
/// 이 언어가 곧 "어느 나라에서 접근했나"다 — 타이틀 화면의 로그인 버튼(한국: 카카오 · 일본: 라인)과
/// 모든 그림·글자가 이것으로 갈린다. 프로필에서 사용자가 고르는 거주 국가와는 **다른 것**이다.
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
      // 지원하지 않는 언어(영어 등)는 **일본어**로 떨어뜨린다(사용자 결정 2026-11-21 — 디폴트는 일본).
      // 예전엔 원문이 한국어라 한국어로 못박았었다. ARB 원문(템플릿)은 여전히 한국어다.
      localeResolutionCallback: (locale, supported) {
        final code = locale?.languageCode;
        if (code != null && supported.any((l) => l.languageCode == code)) {
          return Locale(code);
        }
        return const Locale('ja');
      },
      routerConfig: ref.watch(routerProvider),
    );
  }
}
