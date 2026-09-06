import 'package:flutter/material.dart';

import 'design_canvas.dart';

/// 메인 5탭 하단 내비게이션 (포스트·달빛가든·대화방·친구·프로필).
///
/// **Plan_4에서 그림으로 왔다.** 아이콘·글자가 전부 이미지이고, 탭마다
/// **색상(선택) / 흰색(비선택)** 두 벌이 있다. 그래서 여기엔 `Icons.*`도 `Text`도 없다 —
/// 라벨이 ARB가 아니라 **그림 안에** 있다는 뜻이다(이 앱 UI 언어의 두 번째 종류).
/// 일본어판은 같은 규격의 일본어 글자 이미지를 받아 교체한다.
///
/// 좌표는 시안(`달빛가든 화면_좌표값.png`)의 1080 캔버스 픽셀값을 그대로 옮겼다.
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.selected, required this.onTap});

  final int selected;
  final ValueChanged<int> onTap;

  static const String _dir = 'assets/images/nav';

  /// 외곽선 규격과 위치(시안 `23, 2295`, 1031×218).
  static const double frameWidth = 1031;
  static const double frameHeight = 218;

  /// 탭마다: 에셋 접두어 · 아이콘 크기/위치 · 글자 크기/위치.
  /// 위치는 **외곽선 좌상단(23, 2295) 기준 상대값**이다.
  static const List<_NavSpec> _specs = [
    _NavSpec('post', Size(72, 63), Offset(68, 36), Size(109, 31), Offset(51, 139)),
    _NavSpec('garden', Size(83, 72), Offset(267, 32), Size(146, 39), Offset(235, 136)),
    _NavSpec('chat', Size(69, 73), Offset(478, 32), Size(109, 39), Offset(461, 136)),
    _NavSpec('friend', Size(74, 64), Offset(673, 35), Size(72, 39), Offset(676, 136)),
    _NavSpec('profile', Size(56, 64), Offset(891, 35), Size(107, 38), Offset(873, 136)),
  ];

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);

    // ⚠️ **본문(카드·버튼 줄)과 같은 선에 놓는다.** 예전엔 `Center`로 가운데 정렬했는데,
    // 시안의 주메뉴는 좌우 여백이 다르고(왼쪽 23 · 오른쪽 26) 폭도 카드보다 3px 좁다.
    // 그대로 두면 **끝 라인이 카드와 어긋나 보인다** — 셋을 같은 폭으로 맞춘다.
    final width = DesignCanvas.contentWidth * s;
    // 그림은 1031폭 기준이라, 폭을 1034로 늘린 만큼 **내부 좌표도 같이 늘려야** 한다.
    final fs = width / frameWidth;

    return Padding(
      padding: EdgeInsets.only(bottom: 8 * s),
      child: Center(
        // ⚠️ `heightFactor`가 없으면 Center가 **허용된 최대 높이까지 늘어난다.**
        // bottomNavigationBar가 화면 전체를 차지해 본문 높이가 0이 되고,
        // 내비는 그 안에서 세로 가운데로 가 **화면 중앙에 뜬다**. 1이면 자식 높이만 쓴다.
        heightFactor: 1,
        child: SizedBox(
          width: width,
          height: frameHeight * fs,
          child: Stack(
            children: [
              ArtImage(
                '$_dir/nav_frame.png',
                width: frameWidth,
                height: frameHeight,
                scale: fs,
              ),
              for (var i = 0; i < _specs.length; i++) ..._itemLayers(i, fs),
              // 탭 영역은 그림 위치와 무관하게 **다섯 칸으로 균등 분할**한다.
              // 아이콘·글자 폭이 탭마다 달라 그대로 쓰면 누르기 어려운 칸이 생긴다.
              for (var i = 0; i < _specs.length; i++)
                Positioned(
                  left: width / _specs.length * i,
                  top: 0,
                  width: width / _specs.length,
                  height: frameHeight * fs,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _itemLayers(int i, double s) {
    final spec = _specs[i];
    final suffix = i == selected ? 'on' : 'off';
    return [
      Positioned(
        left: spec.iconAt.dx * s,
        top: spec.iconAt.dy * s,
        child: ArtImage(
          '$_dir/${spec.name}_icon_$suffix.png',
          width: spec.iconSize.width,
          height: spec.iconSize.height,
          scale: s,
        ),
      ),
      Positioned(
        left: spec.textAt.dx * s,
        top: spec.textAt.dy * s,
        child: ArtImage(
          '$_dir/${spec.name}_text_$suffix.png',
          width: spec.textSize.width,
          height: spec.textSize.height,
          scale: s,
        ),
      ),
    ];
  }
}

class _NavSpec {
  const _NavSpec(
    this.name,
    this.iconSize,
    this.iconAt,
    this.textSize,
    this.textAt,
  );

  final String name;
  final Size iconSize;
  final Offset iconAt;
  final Size textSize;
  final Offset textAt;
}
