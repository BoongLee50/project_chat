import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/session_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/onboarding/presentation/screens/birth_date_step_screen.dart';
import '../features/onboarding/presentation/screens/gender_step_screen.dart';
import '../features/onboarding/presentation/screens/nickname_screen.dart';
import '../features/onboarding/presentation/screens/residence_step_screen.dart';
import 'main_shell.dart';

/// 라우트 경로 상수.
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  // 온보딩(가입 정보 입력) — 그래픽 소스 `로그인 화면` STEP 1~7(2026-11-21).
  // 🚧 약관 화면(로그인 다음)은 아직 없다. STEP 4·5·7은 그림이 없어 건너뛰고, STEP 6 닉네임은 옛 화면이 임시로 맡는다.
  static const onboardingGender = '/onboarding/gender'; // STEP 1
  static const onboardingBirth = '/onboarding/birth'; // STEP 2
  static const onboardingResidence = '/onboarding/residence'; // STEP 3
  static const onboardingNickname = '/onboarding/nickname'; // STEP 6(임시 — 옛 화면)
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
        // 온보딩 중에는 단계 화면 사이 이동을 허용. 시작은 STEP 1(성별).
        SessionStatus.onboarding =>
          inOnboarding ? null : Routes.onboardingGender,
        SessionStatus.authenticated =>
          location == Routes.home ? null : Routes.home,
      };
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        // 저장된 토큰을 확인하는 동안 = 타이틀 화면 [자동 로그인] 상태.
        builder: (context, state) => const TitleSplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.onboardingGender,
        builder: (context, state) => const GenderStepScreen(),
      ),
      GoRoute(
        path: Routes.onboardingBirth,
        builder: (context, state) => const BirthDateStepScreen(),
      ),
      GoRoute(
        path: Routes.onboardingResidence,
        builder: (context, state) => const ResidenceStepScreen(),
      ),
      GoRoute(
        path: Routes.onboardingNickname,
        builder: (context, state) => const NicknameScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const MainShell(),
      ),
    ],
  );
});
