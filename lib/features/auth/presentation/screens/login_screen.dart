import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../data/models/auth_models.dart';
import '../providers/session_provider.dart';

/// 로그인 화면.
///
/// 배경은 시안의 밤하늘 이미지(상단), 하단은 시간 배지 + 소셜 로그인 버튼 3종.
/// 버튼을 누르면 `POST /auth/social`로 로그인한다. 실제 소셜 SDK 연동 전까지는
/// 개발용 목 토큰을 보내고 서버의 mock provider가 이를 받아준다
/// (docs/01 §1.1 · 서버 `app.auth.social.mock.enabled`).
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 로그인 실패 메시지를 스낵바로 표시.
    ref.listen(sessionProvider, (previous, next) {
      final message = next.error;
      if (message != null && message != previous?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });

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

class _SocialButtons extends ConsumerWidget {
  const _SocialButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final busy = ref.watch(sessionProvider).busy;

    // 개발용: 소셜 SDK 대신 provider별 목 토큰을 서버에 보낸다.
    // 토큰 문자열이 곧 테스트 계정 식별자라, provider마다 다른 계정이 된다.
    void signIn(SocialProvider provider) {
      if (busy) return;
      ref
          .read(sessionProvider.notifier)
          .signIn(
            provider: provider,
            providerToken: 'dev-${provider.wireName.toLowerCase()}',
          );
    }

    return Column(
      children: [
        _SocialButton(
          label: l10n.loginWithLine,
          background: AppColors.line,
          foreground: Colors.white,
          onPressed: () => signIn(SocialProvider.line),
          leading: _badge(
            bg: Colors.white,
            child: const Icon(
              Icons.chat_bubble,
              size: 16,
              color: AppColors.line,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.gapMd),
        _SocialButton(
          label: l10n.loginWithKakao,
          background: AppColors.kakao,
          foreground: AppColors.kakaoText,
          onPressed: () => signIn(SocialProvider.kakao),
          leading: _badge(
            bg: AppColors.kakaoText,
            child: const Icon(
              Icons.chat_bubble,
              size: 16,
              color: AppColors.kakao,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.gapMd),
        _SocialButton(
          label: l10n.loginWithGoogle,
          background: AppColors.google,
          foreground: AppColors.googleText,
          onPressed: () => signIn(SocialProvider.google),
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
    return Text(
      L10n.of(context).loginTermsNotice,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        height: 1.4,
      ),
    );
  }
}
