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

  /// 주메뉴 그림은 **달빛가든 폴더로 전달됐다**(전용이 아니라 모든 화면이 쓴다).
  static const String _dir = 'assets/images/scene_garden';

  /// 외곽선 규격과 위치(시안 `23, 2295`, 1031×218).
  static const double frameWidth = 1031;
  static const double frameHeight = 218;

  /// 탭마다: 아이콘·글자 **경로**와 크기/위치.
  /// 위치는 **외곽선 좌상단(23, 2295) 기준 상대값**이다.
  ///
  /// ⚠️ **경로를 이름으로 조립하지 않는다.** 전달본의 파일명이 규칙적이지 않기 때문이다 —
  /// 대화방 아이콘은 `menu__room_icon_`(밑줄 둘), 친구 아이콘은 `main_menu_icon_friend_`로
  /// 접두어와 어순이 다르다. 조립하면 그 둘만 조용히 못 찾는다.
  static const List<_NavSpec> _specs = [
    _NavSpec(
      icon: '$_dir/menu_post_icon',
      text: '$_dir/menu_post_text',
      iconSize: Size(72, 63), iconAt: Offset(68, 36),
      textSize: Size(109, 31), textAt: Offset(51, 139),
    ),
    _NavSpec(
      icon: '$_dir/menu_garden_icon',
      text: '$_dir/menu_garden_text',
      iconSize: Size(83, 72), iconAt: Offset(267, 32),
      textSize: Size(146, 39), textAt: Offset(235, 136),
    ),
    _NavSpec(
      icon: '$_dir/menu__room_icon',
      text: '$_dir/menu_room_text',
      iconSize: Size(69, 73), iconAt: Offset(478, 32),
      textSize: Size(109, 39), textAt: Offset(461, 136),
    ),
    _NavSpec(
      icon: '$_dir/main_menu_icon_friend',
      text: '$_dir/menu_friend_text',
      iconSize: Size(74, 64), iconAt: Offset(673, 35),
      textSize: Size(72, 39), textAt: Offset(676, 136),
    ),
    _NavSpec(
      icon: '$_dir/menu_profile_icon',
      text: '$_dir/menu_profile_text',
      iconSize: Size(56, 64), iconAt: Offset(891, 35),
      textSize: Size(107, 38), textAt: Offset(873, 136),
    ),
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
                '$_dir/main_frame.png',
                width: frameWidth,
                height: frameHeight,
                scale: fs,
              ),
              for (var i = 0; i < _specs.length; i++)
                ..._itemLayers(context, i, fs),
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

  List<Widget> _itemLayers(BuildContext context, int i, double s) {
    final spec = _specs[i];
    // 선택된 탭은 `_color`, 나머지는 `_normal`(전달본의 이름 그대로).
    final suffix = i == selected ? '_color.png' : '_normal.png';
    final textAsset = spec.text + suffix;

    // 🚨 **글자는 언어마다 폭이 다르다** — 「月光ガーデン」은 `달빛가든`의 1.6배다(146 → 232).
    // 왼쪽을 고정하면 일본어에서 글자가 아이콘 밑을 벗어나 옆 칸까지 밀고 들어간다.
    // 시안의 글자 상자 **중심**을 잡아 두고 거기에 맞춰 놓는다(아이콘 중심과 같은 선이다).
    final lang = Localizations.localeOf(context).languageCode;
    final textAssetResolved = DesignCanvas.localizedAssetFor(textAsset, lang);
    final textSize = _fitInSlot(
      DesignCanvas.localizedSize(textAsset, lang, spec.textSize),
    );
    final textCenter = spec.textAt + Alignment.center.alongSize(spec.textSize);

    return [
      Positioned(
        left: spec.iconAt.dx * s,
        top: spec.iconAt.dy * s,
        child: ArtImage(
          spec.icon + suffix,
          width: spec.iconSize.width,
          height: spec.iconSize.height,
          scale: s,
        ),
      ),
      Positioned(
        left: (textCenter.dx - textSize.width / 2) * s,
        top: (textCenter.dy - textSize.height / 2) * s,
        // 이미 언어를 적용한 경로·크기를 넘긴다. [ArtImage]가 다시 바꾸지 않는다
        // (풀린 `ja/` 경로는 목록의 키가 아니라서 그대로 나간다).
        child: ArtImage(
          textAssetResolved,
          width: textSize.width,
          height: textSize.height,
          scale: s,
        ),
      ),
    ];
  }

  /// 글자 그림을 **탭 한 칸 안**으로 맞춘다(비율 유지).
  ///
  /// 🚨 **받은 일본어 그림 두 장이 칸보다 넓다** — 「月光ガーデン」 232 ·「プロフィール」 234 대
  /// 한 칸 206. 그대로 그리면 옆 칸 글자와 겹치고 맨 오른쪽은 화면 밖으로 잘린다(실제로 그랬다).
  ///
  /// 줄여서 담는 쪽을 택했다 — 글자가 조금 작아지는 것이 겹치는 것보다 낫다.
  /// 📌 **규격이 맞는 그림을 다시 받으면 이 함수는 아무 일도 하지 않는다**(칸보다 좁으면 그대로).
  static Size _fitInSlot(Size size) {
    final slot = frameWidth / _specs.length * 0.95; // 칸 사이에 숨 쉴 틈을 둔다
    if (size.width <= slot) return size;
    final k = slot / size.width;
    return Size(size.width * k, size.height * k);
  }
}

class _NavSpec {
  const _NavSpec({
    required this.icon,
    required this.text,
    required this.iconSize,
    required this.iconAt,
    required this.textSize,
    required this.textAt,
  });

  /// 접미어(`_color.png` / `_normal.png`) 앞까지의 경로.
  final String icon;
  final String text;

  final Size iconSize;
  final Offset iconAt;
  final Size textSize;
  final Offset textAt;
}
