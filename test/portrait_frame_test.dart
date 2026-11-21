import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_chat/shared/widgets/portrait_frame.dart';

/// 넓은 창에서는 세로 비율(9:16) 상자를 가운데, 폰 비율에서는 그대로(docs/10 §0-9-3).
void main() {
  Future<Size> innerSize(WidgetTester t, Size window) async {
    t.view.physicalSize = window;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late Size seen;
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => PortraitFrame(child: child!),
        home: Builder(builder: (context) {
          seen = MediaQuery.sizeOf(context);
          return const SizedBox.expand();
        }),
      ),
    );
    return seen;
  }

  testWidgets('폰(20:9)은 그대로 — 창 전체를 쓴다', (t) async {
    expect(await innerSize(t, const Size(1080, 2424)), const Size(1080, 2424));
  });

  testWidgets('16:9 폰도 그대로', (t) async {
    expect(await innerSize(t, const Size(900, 1600)), const Size(900, 1600));
  });

  testWidgets('가로 태블릿은 세로 상자를 가운데 — 폭 = 높이 × 9/16', (t) async {
    expect(await innerSize(t, const Size(2560, 1600)), const Size(900, 1600));
  });

  testWidgets('폴드 안쪽(거의 정사각)도 세로 상자', (t) async {
    expect(await innerSize(t, const Size(1812, 2176)), const Size(1224, 2176));
  });

  testWidgets('상자 안 좌우 안전 영역은 0 — 노치는 상자 밖', (t) async {
    t.view.physicalSize = const Size(2560, 1600);
    t.view.devicePixelRatio = 1;
    t.view.padding = const FakeViewPadding(left: 80, top: 40, right: 80);
    addTearDown(t.view.reset);
    late EdgeInsets pad;
    await t.pumpWidget(MaterialApp(
      builder: (context, child) => PortraitFrame(child: child!),
      home: Builder(builder: (context) {
        pad = MediaQuery.paddingOf(context);
        return const SizedBox.expand();
      }),
    ));
    expect(pad.left, 0);
    expect(pad.right, 0);
    expect(pad.top, 40);
  });
}
