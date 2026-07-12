import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../widgets/onboarding_scaffold.dart';
import 'birth_year_screen.dart';

/// 온보딩 1/3 — 닉네임 설정 (정적 UI).
class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  static const int _maxLen = 10;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.trim().length >= 2;

  @override
  Widget build(BuildContext context) {
    final len = _controller.text.characters.length;

    return OnboardingScaffold(
      backgroundAsset: 'assets/images/onboarding_1.jpg',
      title: '닉네임 설정',
      subtitle: '달빛톡에서 사용할 닉네임을 입력해주세요.',
      submitEnabled: _valid,
      onSubmit: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BirthYearScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 입력 필드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: _maxLen,
                    cursorColor: AppColors.moonlight,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      hintText: '닉네임을 입력해주세요',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Text(
                  '$len/$_maxLen',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.gapLg),
          const Text(
            '닉네임 가이드',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimens.gapSm),
          const _Bullet('2자 이상 10자 이하로 입력해주세요.'),
          const _Bullet('특수문자 및 이모지는 사용할 수 없습니다.'),
          const _Bullet('욕설, 혐오 표현 등 부적절한 닉네임은 사용할 수 없습니다.'),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
