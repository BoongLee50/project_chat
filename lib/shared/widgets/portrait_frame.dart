import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 🖥 **넓은 화면에서는 세로 화면을 가운데에** — 태블릿·펼친 폴드·가로 화면 대응
/// (사용자 결정 2026-11-21 · docs/10 §0-9-3).
///
/// 앱은 세로 하나뿐이다. 그런데 안드로이드 16부터 폭 600dp 이상 기기(태블릿·폴드 안쪽 화면)에서는
/// 세로 고정(`screenOrientation="portrait"`)이 **무시된다** — 눕히면 앱 창도 가로가 된다.
/// 화면은 `DesignCanvas.scaleOf`(= 화면 폭 ÷ 1080)로 그려져, 그대로 두면 넓은 창에서 그림이 커져 **아래가 잘린다.**
///
/// 그래서 창이 [maxAspect]보다 넓으면 **세로 비율 상자를 가운데** 두고 양옆은 앱이 직접 배경으로 칠한다
/// (앱이 그리는 레터박스 — 시스템 호환 모드 레터박스가 아니다). 상자 안에서는 [MediaQuery]의 크기가
/// 상자 크기로 바뀌므로 모든 화면·시트·팝업이 **폰에서와 똑같이** 그 안에 그려진다.
///
/// - **폰은 아무것도 달라지지 않는다** — 폰은 [maxAspect]보다 길쭉하다(20:9 ≈ 0.45, 16:9 = 0.5625).
/// - 세로로 조금 넓은 화면(폴드 안쪽 등)도 지금은 같은 상자로 처리한다. 띠 없이 꽉 채우는 "앵커 대응"은
///   화면마다 손이 드는 다듬기라 나중 일이다(docs/10 §0-9-3).
/// - 🚨 화면 코드에서 실제 창 크기(`View.of(context)`의 크기)로 배치하지 말 것 — 그 자리만 상자 밖 크기를 본다.
///   상태바 높이(`padding.top`)는 상자와 같아서 괜찮다.
class PortraitFrame extends StatelessWidget {
  const PortraitFrame({super.key, required this.child});

  final Widget child;

  /// 상자의 최대 가로:세로 = **9:16**. 이보다 넓은 창에서만 상자가 생긴다.
  static const double maxAspect = 9 / 16;

  /// 양옆 띠 색 — 앱 배경색(어두운 남색). 배경 그림을 흐리게 깔지는 나중에 정한다.
  static const Color sideColor = AppColors.night;

  /// 이 창 크기에서 앱이 쓸 상자의 폭. 창이 충분히 길쭉하면 창 폭 그대로다.
  static double boxWidthFor(Size window) =>
      math.min(window.width, window.height * maxAspect);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final boxWidth = boxWidthFor(mq.size);
    if (boxWidth >= mq.size.width) return child; // 폰 — 그대로

    // 상자 안에서는 좌우 안전 영역(가로 화면의 노치 등)이 상자 밖에 있으므로 0으로 둔다.
    EdgeInsets noSides(EdgeInsets e) => e.copyWith(left: 0, right: 0);
    final inner = mq.copyWith(
      size: Size(boxWidth, mq.size.height),
      padding: noSides(mq.padding),
      viewPadding: noSides(mq.viewPadding),
      viewInsets: noSides(mq.viewInsets),
      systemGestureInsets: noSides(mq.systemGestureInsets),
    );

    return ColoredBox(
      color: sideColor,
      child: Center(
        child: SizedBox(
          width: boxWidth,
          height: mq.size.height,
          child: ClipRect(
            child: MediaQuery(data: inner, child: child),
          ),
        ),
      ),
    );
  }
}
