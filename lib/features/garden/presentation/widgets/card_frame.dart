import 'package:flutter/material.dart';

import '../../../../shared/widgets/design_canvas.dart';
import 'garden_art.dart';

/// 포스트 카드의 외곽선. **포스트 화면과 달빛가든이 같이 쓴다.**
///
/// 산 사람이 자기 화면에서 먼저 확인할 수 있어야 하고, 남에게 보이는 모습과
/// 달라서도 안 되기 때문이다(기획 화면 26·29).
///
/// 🚨 **두 그림의 여백이 달라 그대로 채우면 사진과 선이 어긋난다.**
/// 일반 그림은 선이 가장자리에 붙어 있지만, 앨범패스 그림은 발광이 번져
/// **선이 사방 6~8px 안쪽**이다. 그래서 패스 쪽은 그 여백만큼 **상자 밖으로 넓혀** 그린다.
/// 그래야 두 경우 모두 선이 카드 경계에 정확히 얹힌다.
///
/// ⚠️ 이 위젯을 담는 `Stack`은 **`clipBehavior: Clip.none`** 이어야 한다.
/// 기본값(hardEdge)이면 밖으로 넓힌 부분이 잘려 패스 외곽선이 다시 안으로 들어간다.
class CardFrame extends StatelessWidget {
  const CardFrame({super.key, required this.decorated});

  /// 앨범 패스·프라임 보유자의 포스트인가.
  final bool decorated;

  /// 사진을 **선 안쪽으로 밀어 넣는** 여백(논리픽셀).
  ///
  /// 🚨 곡률만 맞춰서는 부족하다. 그건 계산이 정확할 때만 맞고, 기기 비율이나 그림이
  /// 조금만 달라져도 사진이 선 밖으로 삐져나온다(실제로 그렇게 나왔다).
  /// **선 두께만큼 사진을 안으로 넣으면 구조적으로 벗어날 수 없다** —
  /// 사진 가장자리가 선 아래에 살짝 물리므로 틈도 안 생긴다.
  static double photoInset(BuildContext context, bool decorated) {
    final line = decorated
        ? GardenArt.framePassLineWidth
        : GardenArt.frameLineWidth;
    // 선 두께의 70%만 넣는다 — 100%면 사진 끝과 선 안쪽 끝이 정확히 만나
    // 반올림에 따라 머리카락 같은 틈이 보일 수 있다.
    return line * 0.7 * DesignCanvas.scaleOf(context);
  }

  /// 사진을 자를 때 쓸 모서리 — **외곽선과 같은 곡률**에서 [photoInset]만큼 뺀 값이다.
  ///
  /// 카드는 화면 높이에 따라 세로로 눌리는데 그림도 같이 눌리므로,
  /// 자르는 쪽도 **타원 반경**으로 같이 눌러 준다. 원형 반경을 쓰면 코너에서만 어긋난다.
  static BorderRadius clipRadius(
    BuildContext context,
    Size cardSize,
    bool decorated,
  ) {
    const r = GardenArt.frameCornerRadius;
    final inset = photoInset(context, decorated);
    final rx = r * cardSize.width / GardenArt.cardFrameSize.width - inset;
    final ry = r * cardSize.height / GardenArt.cardFrameSize.height - inset;
    return BorderRadius.all(
      Radius.elliptical(rx.clamp(0.0, 999.0), ry.clamp(0.0, 999.0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!decorated) {
      // 여백이 없으니 상자를 그대로 채운다.
      return const IgnorePointer(
        child: Image(
          image: AssetImage(GardenArt.cardFrame),
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
        ),
      );
    }

    // 선 영역이 카드와 일치하도록, 여백 비율만큼 사방으로 넓힌다.
    final pad = GardenArt.framePassPadding;
    final line = GardenArt.framePassLineSize;
    return LayoutBuilder(
      builder: (context, c) {
        final growX = c.maxWidth / line.width;
        final growY = c.maxHeight / line.height;
        return IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -pad.left * growX,
                top: -pad.top * growY,
                right: -pad.right * growX,
                bottom: -pad.bottom * growY,
                child: const Image(
                  image: AssetImage(GardenArt.cardFramePass),
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
