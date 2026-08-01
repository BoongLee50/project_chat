import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/session_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/onboarding/presentation/screens/birth_year_screen.dart';
import '../features/onboarding/presentation/screens/gender_country_screen.dart';
import '../features/onboarding/presentation/screens/nickname_screen.dart';
import 'main_shell.dart';
import 'theme/app_colors.dart';

/// 라우트 경로 상수.
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const onboardingNickname = '/onboarding/nickname';
  static const onboardingBirthYear = '/onboarding/birth-year';
  static const onboardingGender = '/onboarding/gender';
  static const home = '/home';
}

/// 세션 상태에 따라 진입 지점을 결정하는 라우터.
///
/// 인증 게이트: 미로그인 → 로그인, 프로필 미완성 → 온보딩, 완료 → 메인 셸.
/// (시간 게이트(17~06)는 서버 `/system/gate` 기준으로 화면 단에서 처리)
final routerProvider = Provider<GoRouter>((ref) {
  // 세션이 바뀔 때마다 redirect를 다시 평가하도록 알림.
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen(sessionProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(sessionProvider).status;
      final location = state.matchedLocation;
      final inOnboarding = location.startsWith('/onboarding');

      return switch (status) {
        SessionStatus.loading =>
          location == Routes.splash ? null : Routes.splash,
        SessionStatus.unauthenticated =>
          location == Routes.login ? null : Routes.login,
        // 온보딩 중에는 3단계 화면 사이 이동을 허용.
        SessionStatus.onboarding =>
          inOnboarding ? null : Routes.onboardingNickname,
        SessionStatus.authenticated =>
          location == Routes.home ? null : Routes.home,
      };
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.onboardingNickname,
        builder: (context, state) => const NicknameScreen(),
      ),
      GoRoute(
        path: Routes.onboardingBirthYear,
        builder: (context, state) => const BirthYearScreen(),
      ),
      GoRoute(
        path: Routes.onboardingGender,
        builder: (context, state) => const GenderCountryScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const MainShell(),
      ),
    ],
  );
});

/// 저장된 토큰을 확인하는 동안 보여줄 화면.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.moonlight),
      ),
    );
  }
}
