import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../models/auth_models.dart';

/// 소셜 공급자에서 **로그인 토큰**을 받아 오는 단계.
///
/// 로그인은 두 단계다 — ① 여기서 공급자(구글·애플·라인·카카오)의 토큰을 받고
/// ② 그 토큰을 서버 `POST /auth/social`에 보내 우리 계정 토큰으로 바꾼다(`SessionNotifier.signIn`).
/// 서버가 토큰을 **직접 검증**하므로(위조·만료·다른 앱의 토큰 거절) 앱은 받은 것을 그대로 넘기기만 한다.
///
/// | 공급자 | 서버에 보낼 토큰 |
/// |---|---|
/// | 구글 | ID 토큰(`idToken`) — 서버가 tokeninfo로 aud·iss를 본다 |
/// | 애플 | identity token(JWT) — 서버가 애플 공개키로 서명·aud·iss·exp를 본다 |
/// | 라인 | ID 토큰 — 서버가 LINE verify로 본다 |
/// | 카카오 | 액세스 토큰 — 서버가 `access_token_info`로 **우리 앱(app_id)** 것인지 본다 |
abstract class SocialSignIn {
  /// 토큰을 받아 온다. 사용자가 창을 닫으면 [SocialSignInCancelled],
  /// 아직 연결되지 않은 공급자면 [SocialSignInUnavailable].
  Future<String> obtainToken(SocialProvider provider);
}

/// 사용자가 공급자 로그인 창을 닫았다 — 오류가 아니라 **아무 일도 없던 것**으로 처리한다.
class SocialSignInCancelled implements Exception {
  const SocialSignInCancelled();
}

/// 이 빌드에서 아직 쓸 수 없는 공급자다(SDK·키가 아직 없다).
class SocialSignInUnavailable implements Exception {
  const SocialSignInUnavailable(this.provider);
  final SocialProvider provider;
}

/// 개발용 — 공급자 대신 목 토큰을 만든다. 서버 local 프로필의 mock provider가 받아 준다.
/// 토큰 문자열이 곧 테스트 계정이라 공급자마다 다른 계정이 된다(`dev-line` · `dev-apple` …).
class MockSocialSignIn implements SocialSignIn {
  const MockSocialSignIn();

  @override
  Future<String> obtainToken(SocialProvider provider) async =>
      'dev-${provider.wireName.toLowerCase()}';
}

/// 실제 공급자 SDK로 토큰을 받는다.
///
/// 🚧 **2단계(키를 받은 뒤)에 채운다** — 지금은 모두 [SocialSignInUnavailable]을 던져
/// 화면이 *"아직 준비 중"* 이라고 말하게 한다(죽은 버튼을 만들지 않는다).
/// 채울 때 쓸 패키지와 필요한 값(2026-11-15 계획, docs/09 §2-2 F):
///
/// | 공급자 | 패키지 | 필요한 값 |
/// |---|---|---|
/// | 구글 | `google_sign_in` | 웹 클라이언트 ID(`serverClientId` — 받은 ID 토큰의 aud가 이것이 된다) · iOS 클라이언트 ID · 안드로이드 SHA-1 등록 |
/// | 애플 | `sign_in_with_apple` | 아이폰: Xcode에서 Sign in with Apple 켜기 · 안드로이드/웹: Services ID + 돌아올 주소(서버) |
/// | 라인 | `flutter_line_sdk` | Channel ID |
/// | 카카오 | `kakao_flutter_sdk_user` | 네이티브 앱 키 · 안드로이드 키 해시 등록 |
class SdkSocialSignIn implements SocialSignIn {
  const SdkSocialSignIn();

  @override
  Future<String> obtainToken(SocialProvider provider) async =>
      throw SocialSignInUnavailable(provider);
}

/// 지금 빌드가 쓸 방식. 개발 빌드는 목, 릴리스 빌드는 실제 SDK(`AppConfig.useMockLogin`).
final socialSignInProvider = Provider<SocialSignIn>(
  (ref) => AppConfig.useMockLogin ? const MockSocialSignIn() : const SdkSocialSignIn(),
);
