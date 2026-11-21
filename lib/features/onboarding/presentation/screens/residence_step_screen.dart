import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../profile/data/models/profile_catalog.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_frame.dart';

/// 온보딩 STEP 3 — 거주 지역(`그래픽 소스\로그인 화면\3. 거주 지역 선택 화면`).
///
/// 세 줄: **거주 국가 · 거주 지역 · 세부 지역**. 칸 그림은 고른 줄이 보라(`selectregion`), 안 고른 줄이 회색.
/// 이름표·값은 글자다. 줄을 누르면 고르는 시트가 뜬다(🚧 시트 그림은 아직 없다 — 코드로 그린다).
///
/// - 거주 국가는 처음에 **앱 언어의 나라**로 골라 둔다(한국어 → 한국, 그 밖 → 일본). 바꿀 수 있다 —
///   이것이 `users.country`가 되고, 앱 언어(타이틀 버튼)와는 다른 것이다.
/// - 거주 지역은 프로필 **활동 지역**과 같은 목록·코드(`ProfileCatalog.regionsByCountry`)를 쓰고, 그대로 활동 지역 1곳으로 저장된다.
///   ⚠️ 시안은 `서울특별시`(광역 이름)인데 목록은 `서울`(도시 이름)이다 — 목록을 정하면 맞춘다.
/// - 🚧 세부 지역은 목록이 아직 없다 — 누르면 준비 중이라고 말하고, 고르지 않아도 넘어간다.
class ResidenceStepScreen extends ConsumerStatefulWidget {
  const ResidenceStepScreen({super.key});

  @override
  ConsumerState<ResidenceStepScreen> createState() =>
      _ResidenceStepScreenState();
}

class _ResidenceStepScreenState extends ConsumerState<ResidenceStepScreen> {
  @override
  void initState() {
    super.initState();
    // 첫 진입이면 앱 언어의 나라로 골라 둔다(첫 프레임 뒤 — build 중 상태 변경 금지).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(onboardingProvider).country != null) return;
      final ko = Localizations.localeOf(context).languageCode == 'ko';
      ref.read(onboardingProvider.notifier).setCountry(ko ? 'KR' : 'JP');
    });
  }

  Future<String?> _pick(List<(String, String)> options, String? current) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              for (final (code, label) in options)
                ListTile(
                  title: Text(
                    label,
                    style: TextStyle(
                      color: code == current
                          ? OnboardingArt.purple
                          : OnboardingArt.ink,
                      fontSize: 17,
                      fontWeight: code == current
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: code == current
                      ? const Icon(
                          Icons.check_rounded,
                          color: OnboardingArt.purple,
                        )
                      : null,
                  onTap: () => Navigator.of(ctx).pop(code),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final form = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final country = form.country;
    final region = form.region;

    Future<void> pickCountry() async {
      final code = await _pick([
        for (final c in ProfileCatalog.regionsByCountry.keys)
          (c, ProfileCatalog.countryLabel(l10n, c)),
      ], country);
      if (code != null) notifier.setCountry(code);
    }

    Future<void> pickRegion() async {
      if (country == null) return;
      final code = await _pick([
        for (final r
            in ProfileCatalog.regionsByCountry[country] ??
                const <InterestItem>[])
          (r.code, ProfileCatalog.cityLabel(l10n, r.code)),
      ], region);
      if (code != null) notifier.setRegion(code);
    }

    void pickDetail() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.onboardingResidenceDetailSoon)),
        );
    }

    return OnboardingFrame(
      step: 3,
      illustration: OnboardingArt.illustResidence,
      illustrationAt: const Offset(557, 150),
      illustrationSize: const Size(428, 403),
      question: l10n.onboardingResidenceQuestion,
      questionTop: 1040,
      note: l10n.onboardingResidenceNote,
      noteTop: 1885,
      content: (s) => [
        _Row(
          top: 1245,
          label: l10n.onboardingResidenceCountry,
          value: country == null
              ? null
              : ProfileCatalog.countryLabel(l10n, country),
          placeholder: l10n.onboardingResidencePick,
          onTap: pickCountry,
        ),
        _Row(
          top: 1465,
          label: l10n.onboardingResidenceRegion,
          value: region == null ? null : ProfileCatalog.cityLabel(l10n, region),
          placeholder: l10n.onboardingResidencePick,
          onTap: pickRegion,
        ),
        _Row(
          top: 1685,
          label: l10n.onboardingResidenceDetail,
          value: null,
          placeholder: l10n.onboardingResidencePick,
          onTap: pickDetail,
        ),
      ],
      onBack: () => context.go(Routes.onboardingBirth),
      onNext: () async {
        if (country == null || region == null) {
          return l10n.onboardingResidenceQuestion;
        }
        // 🚧 STEP 4~7 그림이 아직 없다 — 관심사·자기소개·사진은 건너뛰고(프로필에서 채운다)
        // 옛 닉네임 화면으로 가서 가입을 마친다.
        context.go(Routes.onboardingNickname);
        return null;
      },
    );
  }
}

/// 한 줄 — 칸 그림(906×138) 위에 이름표(x 166)와 값(x 475). 값이 있으면 보라 칸·보라 글자.
class _Row extends StatelessWidget {
  const _Row({
    required this.top,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final double top;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final picked = value != null;
    return Positioned(
      left: 96 * s,
      top: top * s,
      width: 907 * s,
      height: 138 * s,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          children: [
            ArtImage(
              picked ? OnboardingArt.regionOn : OnboardingArt.regionOff,
              width: picked ? 906 : 907,
              height: 138,
            ),
            Positioned(
              left: 70 * s,
              top: 0,
              bottom: 0,
              width: 230 * s,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xFF4A4C4B),
                      fontSize: 52 * s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 379 * s,
              top: 0,
              bottom: 0,
              right: 150 * s,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value ?? placeholder,
                    style: TextStyle(
                      color: picked
                          ? const Color(0xFF683DC4)
                          : const Color(0xFF6B6B6F),
                      fontSize: 52 * s,
                      fontWeight: picked ? FontWeight.w800 : FontWeight.w600,
                    ),
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
