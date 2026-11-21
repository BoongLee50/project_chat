import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_frame.dart';

/// 온보딩 STEP 1 — 성별(`그래픽 소스\로그인 화면\1. 성별 선택 화면`).
///
/// 남·여 그림 버튼 둘(선택 · 미선택 두 벌). 고르지 않고 `>`를 누르면 질문 문구로 이유를 말한다.
/// `<` 버튼은 **없다** — 로그인하면 되돌아갈 필요가 없다(사용자 2026-11-21).
class GenderStepScreen extends ConsumerWidget {
  const GenderStepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final gender = ref.watch(onboardingProvider.select((f) => f.gender));
    final notifier = ref.read(onboardingProvider.notifier);

    Widget choice(String value, double left, String on, String off) =>
        DesignPositioned(
          left: left,
          top: 1246,
          child: GestureDetector(
            onTap: () => notifier.setGender(value),
            child: ArtImage(
              gender == value ? on : off,
              width: 415,
              height: 458,
            ),
          ),
        );

    return OnboardingFrame(
      step: 1,
      illustration: OnboardingArt.illustGender,
      illustrationAt: const Offset(491, 144),
      illustrationSize: const Size(513, 421),
      question: l10n.onboardingGenderQuestion,
      questionTop: 1040,
      note: l10n.onboardingGenderNote,
      noteTop: 1775,
      content: (s) => [
        choice('MALE', 96, OnboardingArt.maleOn, OnboardingArt.maleOff),
        choice('FEMALE', 557, OnboardingArt.femaleOn, OnboardingArt.femaleOff),
      ],
      // 로그인 직후 첫 단계라 되돌아갈 곳이 없다 — `<` 없음(사용자 2026-11-21).
      onBack: null,
      onNext: () async {
        if (gender == null) return l10n.onboardingGenderQuestion;
        context.go(Routes.onboardingBirth);
        return null;
      },
    );
  }
}
