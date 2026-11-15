import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../../core/config/app_config.dart';
import '../../data/models/auth_models.dart';
import '../../data/social/social_sign_in.dart';
import '../providers/session_provider.dart';

/// 로그인 화면.
///
/// 배경은 시안의 밤하늘 이미지(상단), 하단은 소셜 로그인 버튼 — **라인 · 카카오 · 구글 · 애플**(애플은 2026-11-15 추가).
/// 버튼을 누르면 ① 공급자 토큰을 받고([SocialSignIn]) ② `POST /auth/social`로 우리 계정에 로그인한다.
/// 개발 빌드는 목 토큰을 보내고 서버의 mock provider가 받아 준다(docs/01 §1.1 · 서버 `app.auth.social.mock.enabled`).
///
/// ⚠️ 버튼은 아직 **코드로 그린 자리 표시**다 — 로그인 화면 그림(버튼 4 · 배경, 한·일)이 오면 바꾼다.
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
          //
          // 🚨 이 그림에는 **글자가 구워져 있다**(현재 한국어 *"밤에만 만나는 대화"* —
          // 야간 게이트가 폐지돼 내용 자체가 틀렸다. 새 그림 대기 중, 08 참고).
          // 언어별 교체 통로를 미리 거쳐 둔다 — 일본어판이 오면
          // `DesignCanvas.localizedAssets`에 한 줄 더하는 것으로 켜진다.
          Image.asset(
            DesignCanvas.localizedAsset(context, 'assets/images/login_bg.jpg'),
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

    // ① 공급자 토큰(개발 빌드는 목) → ② 서버 로그인. 창을 닫으면 아무 일도 없던 것으로,
    // 아직 연결 안 된 공급자면 이유를 말한다(버튼을 죽이지 않는다).
    Future<void> signIn(SocialProvider provider) async {
      if (busy) return;
      final String token;
      try {
        token = await ref.read(socialSignInProvider).obtainToken(provider);
      } on SocialSignInCancelled {
        return;
      } on SocialSignInUnavailable {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.loginProviderUnavailable)));
        }
        return;
      }
      await ref
          .read(sessionProvider.notifier)
          .signIn(provider: provider, providerToken: token);
    }

    // 애플은 **아이폰에서만** 보인다(안드로이드는 웹 방식이라 서버 설정이 더 든다 — 사용자에게 확인 대기).
    // 개발(목) 빌드는 어디서든 보여서 안드로이드 에뮬에서도 흐름을 시험할 수 있다.
    final showApple = defaultTargetPlatform == TargetPlatform.iOS || AppConfig.useMockLogin;

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
        if (showApple) ...[
          const SizedBox(height: AppDimens.gapMd),
          _SocialButton(
            label: l10n.loginWithApple,
            background: AppColors.apple,
            foreground: AppColors.appleText,
            // 검은 버튼이 어두운 배경에 묻히지 않게 흰 테두리 — 애플 가이드의 "흰 테두리 검은 버튼" 형태.
            borderColor: AppColors.appleText,
            onPressed: () => signIn(SocialProvider.apple),
            leading: _badge(
              bg: AppColors.appleText,
              child: const Icon(Icons.apple, size: 18, color: AppColors.apple),
            ),
          ),
        ],
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
    this.borderColor,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Widget leading;
  final VoidCallback onPressed;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.buttonHeight,
      width: double.infinity,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor!),
        ),
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
