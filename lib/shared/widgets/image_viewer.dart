import 'package:flutter/material.dart';

import '../../app/theme/app_dimens.dart';
import 'authed_image.dart';

/// 원본 사진만 팝업으로 띄운다(기획 4-2 / 8-2: "클릭 시 원본 사진만 팝업 형식으로 출력").
///
/// 배경을 눌러도 닫히고(`barrierDismissible` 기본값), 우상단 X로도 닫힌다.
/// 확대·저장 같은 건 기획에 없으므로 넣지 않는다 — **보여 주기만 한다.**
Future<void> showOriginalImage(BuildContext context, String url) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            // 원본 비율 그대로. cover로 채우면 "원본"이 아니게 된다.
            child: AuthedImage(url: url, fit: BoxFit.contain),
          ),
          // 닫기 버튼은 **사진 위에 얹힌다** — 밝은 사진이 오면 흰 아이콘이 묻힌다.
          // 어두운 원을 깔아 어떤 사진에서도 보이게 한다.
          Padding(
            padding: const EdgeInsets.all(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 누르면 원본이 뜨는 사진.
///
/// ⚠️ **`HitTestBehavior.opaque`가 반드시 있어야 한다.** `GestureDetector`의 기본값은
/// `deferToChild`이고 `Image`는 자기 자신을 히트테스트하지 않아, 그냥 감싸면
/// **눌러도 아무 일이 일어나지 않는다**(함정 #38). 이 위젯을 쓰는 이유가 그것이다 —
/// 사진을 누르는 자리가 늘 때마다 같은 실수를 반복하지 않도록 한곳에 모아 둔다.
class TappableImage extends StatelessWidget {
  const TappableImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final double? width;
  final double? height;

  /// 크기를 비율로 줄 때. [width]·[height]와 함께 쓰지 않는다.
  final double? aspectRatio;

  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget image = AuthedImage(url: url, fit: fit);
    if (aspectRatio != null) {
      image = AspectRatio(aspectRatio: aspectRatio!, child: image);
    } else if (width != null || height != null) {
      image = SizedBox(width: width, height: height, child: image);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showOriginalImage(context, url),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(AppDimens.radiusMd),
        child: image,
      ),
    );
  }
}
