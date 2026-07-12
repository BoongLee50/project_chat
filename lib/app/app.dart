import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import 'theme/app_theme.dart';

/// 앱 루트 위젯.
///
/// 지금은 스캐폴딩 단계라 정적 홈만 표시한다.
/// 이후 단계에서 연결할 것:
///  - 상태관리: ProviderScope(Riverpod)로 감싸기
///  - 라우팅: MaterialApp.router + go_router (시간/인증 2단 게이트)
///  - 다국어: 한국어/일본어 로케일
/// 자세한 내용은 docs/03-flutter-structure.md 참고.
class DalbittokApp extends StatelessWidget {
  const DalbittokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '달빛톡',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const LoginScreen(),
    );
  }
}
