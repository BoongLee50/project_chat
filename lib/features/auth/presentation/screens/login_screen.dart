import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/auth_models.dart';
import '../../data/social/social_sign_in.dart';
import '../providers/session_provider.dart';
import '../widgets/title_art.dart';

/// 타이틀(로그인) 화면 — [로그인 선택] 상태(`그래픽 소스\로그인 화면\타이틀 화면`, 2026-11-21).
///
/// - **기기 언어가 나라다**(사용자 결정 2026-11-21): 한국어 → 카카오 · 애플 · 구글 / 그 밖(일본어 · 기본값) → 라인 · 애플 · 구글.
///   그림·글자도 그 언어로 나온다. 프로필에서 고르는 거주 국가와는 다른 것이다.
/// - 버튼을 누르면 ① 공급자 토큰을 받고([SocialSignIn]) ② `POST /auth/social`로 우리 계정에 로그인한다.
///   개발 빌드는 목 토큰을 보내고 서버의 mock provider가 받아 준다(docs/01 §1.1).
/// - 로그인 뒤: 새 회원은 **약관 화면**(🚧 미구현 — 지금은 바로 온보딩 STEP 1) → 온보딩 일곱 단계.
///
/// 같은 판의 [자동 로그인] 상태(버튼 없이 타이틀만 가운데)는 [TitleSplashScreen].
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

    final l10n = L10n.of(context);
    final ja = Localizations.localeOf(context).languageCode != 'ko';
    final busy = ref.watch(sessionProvider).busy;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

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

    // 애플은 **아이폰에서만** 보인다(안드로이드는 웹 방식이라 서버 설정이 더 든다 — 사용자 결정 대기, 09 §2-2 F).
    // 개발(목) 빌드는 어디서든 보여서 안드로이드 에뮬에서도 흐름을 시험할 수 있다.
    final showApple = defaultTargetPlatform == TargetPlatform.iOS || AppConfig.useMockLogin;

    // 위에서부터 칸을 채운다 — 애플이 빠지면 구글이 둘째 칸으로 올라온다.
    final buttons = <(String, double, SocialProvider)>[
      ja
          ? (TitleArt.buttonLine, 142, SocialProvider.line)
          : (TitleArt.buttonKakao, 137, SocialProvider.kakao),
      if (showApple) (TitleArt.buttonApple, 136, SocialProvider.apple),
      (TitleArt.buttonGoogle, 136, SocialProvider.google),
    ];

    return Scaffold(
      body: TitleFrame(
        builder: (context, place) => [
          place.art(
            TitleArt.title,
            left: TitleArt.titleLeft(ja),
            top: TitleArt.titleTopLogin,
            size: TitleArt.titleSize,
          ),
          for (var i = 0; i < buttons.length; i++)
            Positioned(
              left: place.x(TitleArt.buttonLeft),
              top: place.y(TitleArt.buttonTops[i]),
              child: Opacity(
                opacity: busy ? 0.6 : 1,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => signIn(buttons[i].$3),
                  child: ArtImage(
                    buttons[i].$1,
                    width: TitleArt.buttonWidth,
                    height: buttons[i].$2,
                    scale: place.scale,
                  ),
                ),
              ),
            ),
          // 아래 안내 — 글자(폰트). 화면이 시안보다 짧아 잘리는 폰에서도 시스템 바에 묻히지 않게 끌어올린다.
          Positioned(
            left: 0,
            right: 0,
            top: place
                .y(TitleArt.noticeTop)
                .clamp(0.0, place.screen.height - safeBottom - 64 * place.scale),
            child: Text(
              l10n.loginChooseMethod,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 42 * place.scale,
                fontWeight: FontWeight.w500,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
            ),
          ),
          if (busy)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}

/// 타이틀 화면 [자동 로그인] 상태 — 저장된 토큰을 확인하는 동안(스플래시) 보인다.
/// 버튼 없이 타이틀만 가운데(시안 `타이틀 화면_자동 로그인_좌표값.png`).
class TitleSplashScreen extends StatelessWidget {
  const TitleSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ja = Localizations.localeOf(context).languageCode != 'ko';
    return Scaffold(
      body: TitleFrame(
        builder: (context, place) => [
          place.art(
            TitleArt.title,
            left: TitleArt.titleLeft(ja),
            top: TitleArt.titleTopAuto(ja),
            size: TitleArt.titleSize,
          ),
        ],
      ),
    );
  }
}
