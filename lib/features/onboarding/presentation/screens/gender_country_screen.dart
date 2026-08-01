import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';

/// 온보딩 3/3 — 성별 및 나라 설정.
/// [완료] 시 `POST /profile`로 프로필을 생성하고, 세션이 authenticated로 바뀌면
/// 라우터가 자동으로 홈(메인 셸)으로 보낸다.
class GenderCountryScreen extends ConsumerStatefulWidget {
  const GenderCountryScreen({super.key});

  @override
  ConsumerState<GenderCountryScreen> createState() =>
      _GenderCountryScreenState();
}

class _GenderCountryScreenState extends ConsumerState<GenderCountryScreen> {
  /// 서버 enum 값(MALE | FEMALE)
  String? _gender;

  /// 서버 enum 값(KR | JP)
  String? _country;

  bool get _valid => _gender != null && _country != null;

  Future<void> _finish() async {
    final controller = ref.read(onboardingProvider.notifier);
    controller.setGender(_gender!);
    controller.setCountry(_country!);
    await controller.submitProfile();
    // 성공 시 세션 상태 변경 → router redirect가 홈으로 이동시킨다.
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(onboardingProvider);

    ref.listen(onboardingProvider, (previous, next) {
      final message = next.error;
      if (message != null && message != previous?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return OnboardingScaffold(
      backgroundAsset: 'assets/images/onboarding_3.jpg',
      title: '성별 및 나라 설정',
      subtitle: '정확한 매칭을 위해 성별과 나라를 선택해주세요.',
      note: '* 이 정보는 다른 사용자에게 공개되지 않습니다.',
      submitEnabled: _valid && !form.busy,
      onSubmit: _finish,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('성별 선택'),
          const SizedBox(height: AppDimens.gapMd),
          Row(
            children: [
              Expanded(
                child: _SelectCard(
                  leading: const Icon(Icons.person_outline, size: 24),
                  label: '남자',
                  selected: _gender == 'MALE',
                  onTap: () => setState(() => _gender = 'MALE'),
                ),
              ),
              const SizedBox(width: AppDimens.gapMd),
              Expanded(
                child: _SelectCard(
                  leading: const Icon(Icons.person_outline, size: 24),
                  label: '여자',
                  selected: _gender == 'FEMALE',
                  onTap: () => setState(() => _gender = 'FEMALE'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapXl),
          const _SectionLabel('나라 선택'),
          const SizedBox(height: AppDimens.gapMd),
          Row(
            children: [
              Expanded(
                child: _SelectCard(
                  leading: const Text('🇰🇷', style: TextStyle(fontSize: 22)),
                  label: '한국',
                  selected: _country == 'KR',
                  onTap: () => setState(() => _country = 'KR'),
                ),
              ),
              const SizedBox(width: AppDimens.gapMd),
              Expanded(
                child: _SelectCard(
                  leading: const Text('🇯🇵', style: TextStyle(fontSize: 22)),
                  label: '일본',
                  selected: _country == 'JP',
                  onTap: () => setState(() => _country = 'JP'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.leading,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceHigh : AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: selected ? AppColors.moonlight : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: selected
                      ? AppColors.moonlight
                      : AppColors.textSecondary,
                ),
                child: leading,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.moonlight : AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
