import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../widgets/onboarding_scaffold.dart';

/// 온보딩 3/3 — 성별 및 나라 설정 (정적 UI).
class GenderCountryScreen extends StatefulWidget {
  const GenderCountryScreen({super.key});

  @override
  State<GenderCountryScreen> createState() => _GenderCountryScreenState();
}

class _GenderCountryScreenState extends State<GenderCountryScreen> {
  String? _gender; // 'male' | 'female'
  String? _country; // 'kr' | 'jp'

  bool get _valid => _gender != null && _country != null;

  void _finish() {
    // 정적 UI — 실제 프로필 생성 API 연동은 이후 단계.
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필이 생성되었어요. 달빛 아래에서 만나요 🌙')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      backgroundAsset: 'assets/images/onboarding_3.jpg',
      title: '성별 및 나라 설정',
      subtitle: '정확한 매칭을 위해 성별과 나라를 선택해주세요.',
      note: '* 이 정보는 다른 사용자에게 공개되지 않습니다.',
      submitEnabled: _valid,
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
                  selected: _gender == 'male',
                  onTap: () => setState(() => _gender = 'male'),
                ),
              ),
              const SizedBox(width: AppDimens.gapMd),
              Expanded(
                child: _SelectCard(
                  leading: const Icon(Icons.person_outline, size: 24),
                  label: '여자',
                  selected: _gender == 'female',
                  onTap: () => setState(() => _gender = 'female'),
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
                  selected: _country == 'kr',
                  onTap: () => setState(() => _country = 'kr'),
                ),
              ),
              const SizedBox(width: AppDimens.gapMd),
              Expanded(
                child: _SelectCard(
                  leading: const Text('🇯🇵', style: TextStyle(fontSize: 22)),
                  label: '일본',
                  selected: _country == 'jp',
                  onTap: () => setState(() => _country = 'jp'),
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
                  color: selected ? AppColors.moonlight : AppColors.textSecondary,
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
