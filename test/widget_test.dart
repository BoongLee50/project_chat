// 앱 부팅 스모크 테스트.
// 저장된 토큰이 없으면 스플래시(타이틀 [자동 로그인]) → 타이틀 [로그인 선택]으로 이동해야 한다.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_chat/app/app.dart';
import 'package:project_chat/core/providers.dart';
import 'package:project_chat/core/storage/token_storage.dart';

/// 테스트에서는 보안 저장소(플랫폼 채널)를 쓸 수 없어 가짜 구현을 주입한다.
class _EmptyTokenStorage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('토큰이 없으면 로그인 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_EmptyTokenStorage()),
        ],
        child: const DalbittokApp(),
      ),
    );

    // 스플래시 → 세션 복구(토큰 없음) → 로그인으로 리다이렉트
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 테스트 로케일(en)은 지원 언어가 아니라 **일본어**로 폴백된다(app.dart의
    // localeResolutionCallback — 사용자 결정 2026-11-21 "디폴트는 일본").
    // 일본이면 라인 · 애플 · 구글 버튼(그림)과 일본어 안내가 나온다.
    expect(find.text('ログイン方法を選択してください'), findsOneWidget);
    bool usesAsset(Widget w, String path) =>
        w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == path;
    expect(
      find.byWidgetPredicate(
        (w) => usesAsset(w, 'assets/images/scene_login/title/button_line_jp.png'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => usesAsset(w, 'assets/images/scene_login/title/button_kakao_kr.png'),
      ),
      findsNothing,
    );
  });
}
