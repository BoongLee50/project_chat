// 스캐폴딩 스모크 테스트.
// 실제 화면이 붙으면 feature별 테스트로 대체한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:project_chat/app/app.dart';

void main() {
  testWidgets('앱이 스캐폴딩 상태로 렌더된다', (WidgetTester tester) async {
    await tester.pumpWidget(const DalbittokApp());

    expect(find.text('달빛톡 · scaffold'), findsOneWidget);
  });
}
