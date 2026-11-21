import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../profile/data/models/profile_catalog.dart';
import '../../../profile/presentation/widgets/profile_notice_dialog.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_frame.dart';

/// 온보딩 STEP 4 — 관심사(`그래픽 소스\로그인 화면\4. 관심사 등록 화면`, 2026-11-21).
///
/// **목록·규칙은 프로필 [관심사]와 같다**(사용자 2026-11-21 — "기존 스펙대로"):
/// 37종 · 네 묶음(`ProfileCatalog.interestGroups`) · **최대 3개** · 넘기면 버튼을 죽이지 않고
/// 프로필과 같은 안내 팝업(`interestsEditLimit`). 고른 것은 가입을 마칠 때 프로필 관심사로 저장된다.
///
/// - 시안의 묶음(여행 · 문화, 예술)과 항목(해외여행 · 국내여행 …)은 **그림 예시**라 따르지 않는다 —
///   모양과 좌표만 가져온다: 묶음 아이콘 95 · 이름 251 · 칩 265×114가 한 줄에 셋(95 / 409 / 722), 줄 간격 147.
/// - 칩은 **틀 그림(`frame_interest_*`) + 이름 글자**다. 고른 칩은 보라 틀·흰 글자.
/// - 묶음 아이콘은 두 장만 왔다 — 취미 ← `icon_interest_trip`(여행 가방) · 문화 ← `icon_interest_art`(카메라).
///   라이프스타일·스포츠는 🚧 `Icons.*` 자리 표시(08 §0-4).
/// - 37종이 한 화면을 넘는다 → 판(머리·질문·`<` `>`)은 고정이고 **질문 아래 목록 칸만** 스크롤한다.
/// - 🚧 `STEP 4` 배지 그림이 안 왔다 — 판이 같은 자리에 보라 알약을 그린다.
/// - 하나도 안 고르면 넘어가지 않고 이유를 말한다(1~3단계처럼 이 단계도 채우고 간다).
class InterestStepScreen extends ConsumerWidget {
  const InterestStepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final selected = ref.watch(onboardingProvider).interests;

    void toggle(String code) {
      if (!selected.contains(code) &&
          selected.length >= ProfileCatalog.maxInterests) {
        showProfileNotice(
          context,
          l10n.interestsEditLimit(ProfileCatalog.maxInterests),
        );
        return;
      }
      ref.read(onboardingProvider.notifier).toggleInterest(code);
    }

    return OnboardingFrame(
      step: 4,
      illustration: OnboardingArt.illustInterest,
      illustrationAt: const Offset(530, 137),
      illustrationSize: const Size(479, 440),
      question: l10n.onboardingInterestQuestion(ProfileCatalog.maxInterests),
      questionTop: 1040,
      body: _InterestList(selected: selected, onTap: toggle),
      onBack: () => context.go(Routes.onboardingResidence),
      onNext: () async {
        if (selected.isEmpty) return l10n.onboardingInterestRequired;
        // 🚧 STEP 5(자기소개)·7(사진) 그림이 아직 없다 — 옛 닉네임 화면으로 가서 가입을 마친다.
        context.go(Routes.onboardingNickname);
        return null;
      },
    );
  }
}

/// 질문 아래 목록 — 묶음마다 [아이콘 + 이름] 한 줄, 그 아래 칩 셋씩.
class _InterestList extends StatelessWidget {
  const _InterestList({required this.selected, required this.onTap});

  final List<String> selected;
  final ValueChanged<String> onTap;

  /// 묶음 아이콘 — 온 그림만. 없으면 null(자리 표시).
  static (String, Size)? _groupArt(String group) => switch (group) {
    'HOBBY' => (OnboardingArt.groupTrip, const Size(94, 127)),
    'CULTURE' => (OnboardingArt.groupArt, const Size(123, 98)),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final l10n = L10n.of(context);
    final groups = ProfileCatalog.interestGroups;

    return SingleChildScrollView(
      // 질문 한 줄 아래(1150) → 첫 묶음 아이콘(1218). 끝은 버튼 위로 조금 띄운다.
      padding: EdgeInsets.fromLTRB(95 * s, 68 * s, 92 * s, 60 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var g = 0; g < groups.length; g++) ...[
            // 마지막 칩 아랫변(1651) → 다음 묶음 아이콘(1764).
            if (g > 0) SizedBox(height: 113 * s),
            SizedBox(
              height: 127 * s,
              child: Row(
                children: [
                  SizedBox(
                    width: 156 * s, // 아이콘 95 → 이름 251
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: switch (_groupArt(groups[g].code)) {
                        (final String art, final Size size) => ArtImage(
                          art,
                          width: size.width,
                          height: size.height,
                        ),
                        null => Icon(
                          groups[g].icon,
                          size: 100 * s,
                          color: OnboardingArt.purple,
                        ),
                      },
                    ),
                  ),
                  Expanded(
                    child: Text(
                      ProfileCatalog.groupTitle(l10n, groups[g].code),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: OnboardingArt.purple,
                        fontSize: 64 * s,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 아이콘 아랫변(1345) → 칩 윗변(1390).
            SizedBox(height: 45 * s),
            Wrap(
              spacing: 49 * s, // 95+265 → 409
              runSpacing: 33 * s, // 1390+114 → 1537
              children: [
                for (final item in groups[g].items)
                  _Chip(
                    label: ProfileCatalog.interestLabel(l10n, item.code),
                    on: selected.contains(item.code),
                    onTap: () => onTap(item.code),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 칩 하나 — 틀 그림(265×114) 위에 이름. 길면(일본어 등) 줄여서 틀 안에.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 265 * s,
        height: 114 * s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ArtImage(
              on ? OnboardingArt.chipOn : OnboardingArt.chipOff,
              width: 265,
              height: 114,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * s),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    // 시안 실측 — 안 고른 칩 회색(130,129,132) · 고른 칩 흰색.
                    color: on ? Colors.white : const Color(0xFF828184),
                    fontSize: 46 * s,
                    fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
