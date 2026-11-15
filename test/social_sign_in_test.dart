import 'package:flutter_test/flutter_test.dart';
import 'package:project_chat/features/auth/data/models/auth_models.dart';
import 'package:project_chat/features/auth/data/social/social_sign_in.dart';

void main() {
  test('공급자는 넷이고 서버 값과 같다(애플 추가 2026-11-15)', () {
    expect(SocialProvider.values.map((p) => p.wireName), ['LINE', 'KAKAO', 'GOOGLE', 'APPLE']);
  });

  test('개발용 목은 공급자마다 다른 테스트 계정 토큰을 만든다', () async {
    const mock = MockSocialSignIn();
    expect(await mock.obtainToken(SocialProvider.apple), 'dev-apple');
    expect(await mock.obtainToken(SocialProvider.line), 'dev-line');
  });

  test('실제 SDK는 2단계 전까지 "아직 준비 중"을 알린다(죽은 버튼 금지)', () async {
    const sdk = SdkSocialSignIn();
    for (final p in SocialProvider.values) {
      await expectLater(sdk.obtainToken(p), throwsA(isA<SocialSignInUnavailable>()));
    }
  });
}
