// 스캐폴딩 스모크 테스트.
// 실제 화면이 붙으면 feature별 테스트로 대체한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:project_chat/app/app.dart';

void main() {
  testWidgets('로그인 화면이 렌더되고 소셜 버튼이 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const DalbittokApp());

    expect(find.text('LINE으로 로그인'), findsOneWidget);
    expect(find.text('카카오톡으로 로그인'), findsOneWidget);
    expect(find.text('Google로 로그인'), findsOneWidget);
  });
}
