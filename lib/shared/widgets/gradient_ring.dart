import 'package:flutter/material.dart';

/// 라운드 사각을 따라 **그러데이션 선 하나**를 긋는다.
///
/// 포스트 사진의 꾸미기 외곽선(기획 화면 26·29 "무지개빛 테두리 효과")에 쓴다.
///
/// 왜 위젯을 따로 만드나 — Flutter의 `Border`는 **단색만** 받는다.
/// `Container`에 그러데이션 배경을 깔고 안쪽을 덮는 방법도 있지만, 그러면
/// 안쪽 위젯이 배경을 가려야 해서 투명한 카드 위에는 쓸 수 없다.
/// 선만 긋는 편이 겹쳐 얹기에도 안전하다.
class GradientRing extends StatelessWidget {
  const GradientRing({
    super.key,
    required this.radius,
    required this.width,
    required this.colors,
  });

  final double radius;
  final double width;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _RingPainter(radius: radius, width: width, colors: colors),
        // 부모가 준 만큼 다 쓴다(Stack 안에서 fit: expand로 쓰인다).
        size: Size.infinite,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.radius,
    required this.width,
    required this.colors,
  });

  final double radius;
  final double width;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    // 선은 경로의 **가운데**에 그려지므로 반쪽만큼 안으로 들여야 밖으로 삐져나가지 않는다.
    final inset = width / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - width,
      size.height - width,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = SweepGradient(colors: colors).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius - inset)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.radius != radius || old.width != width || old.colors != colors;
}
