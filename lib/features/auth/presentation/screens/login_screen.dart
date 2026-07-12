import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../onboarding/presentation/screens/nickname_screen.dart';

/// 로그인 화면 (정적 UI).
///
/// 배경은 시안에서 뽑은 밤하늘 이미지(상단), 하단은 코드로 구성한
/// 시간 배지 + 소셜 로그인 버튼 3종. 실제 소셜 인증 연동은 이후 단계.
/// (docs/01-protocol-api-spec.md · 소셜 개발자 앱 키 발급 필요)
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 사진 (밤의 한·일 정취)
          Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          // 아래로 갈수록 어두워지는 스크림 — 버튼 가독성 확보
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.nightScrim),
          ),
          // 하단 컨텐츠
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.pagePad),
              child: Column(
                children: const [
                  Spacer(), // 상단 풍경(타이틀 포함)이 보이도록 밀어냄
                  _TimeBadge(),
                  SizedBox(height: AppDimens.gapLg),
                  _SocialButtons(),
                  SizedBox(height: AppDimens.gapLg),
                  _Disclaimer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "밤 6시 ~ 새벽 5시" 운영시간 배지.
class _TimeBadge extends StatelessWidget {
  const _TimeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: const [
          Icon(Icons.nightlight_round, color: AppColors.moonlight, size: 30),
          SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '밤 6시 ~ 새벽 5시',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '밤에만 열리는 채팅의 시간',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 소셜 로그인 버튼 3종.
class _SocialButtons extends StatelessWidget {
  const _SocialButtons();

  @override
  Widget build(BuildContext context) {
    // 정적 UI 흐름 — 실제 소셜 인증 대신 온보딩(프로필 생성)으로 이동한다.
    void startOnboarding() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NicknameScreen()),
        );

    return Column(
      children: [
        _SocialButton(
          label: 'LINE으로 로그인',
          background: AppColors.line,
          foreground: Colors.white,
          onPressed: startOnboarding,
          leading: _badge(
            bg: Colors.white,
            child: const Icon(Icons.chat_bubble, size: 16, color: AppColors.line),
          ),
        ),
        const SizedBox(height: AppDimens.gapMd),
        _SocialButton(
          label: '카카오톡으로 로그인',
          background: AppColors.kakao,
          foreground: AppColors.kakaoText,
          onPressed: startOnboarding,
          leading: _badge(
            bg: AppColors.kakaoText,
            child: const Icon(Icons.chat_bubble, size: 16, color: AppColors.kakao),
          ),
        ),
        const SizedBox(height: AppDimens.gapMd),
        _SocialButton(
          label: 'Google로 로그인',
          background: AppColors.google,
          foreground: AppColors.googleText,
          onPressed: startOnboarding,
          leading: _badge(
            bg: Colors.white,
            child: const Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _badge({required Color bg, required Widget child}) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: child,
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.leading,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Widget leading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.buttonHeight,
      width: double.infinity,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                leading,
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 28), // leading 폭 보정 → 라벨 중앙 정렬
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '로그인하면 서비스 이용약관 및 개인정보처리방침에 동의하게 됩니다.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
    );
  }
}
