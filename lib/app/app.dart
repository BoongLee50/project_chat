import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';

/// 앱 루트 위젯.
///
/// 상태관리는 Riverpod(main.dart의 ProviderScope), 라우팅은 go_router.
/// 진입 화면은 세션 상태에 따라 [routerProvider]가 결정한다.
class DalbittokApp extends ConsumerWidget {
  const DalbittokApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '달빛톡',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
