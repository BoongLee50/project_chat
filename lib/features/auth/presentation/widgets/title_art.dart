import 'package:flutter/material.dart';

import '../../../../shared/widgets/design_canvas.dart';

/// 타이틀(로그인) 화면 그림 — `그래픽 소스\로그인 화면\타이틀 화면`(2026-11-21).
///
/// 🇰🇷/🇯🇵 **기기 언어가 곧 나라다**(사용자 결정 2026-11-21) — 한국어면 카카오 · 애플 · 구글,
/// 그 밖(일본어 · 기본값)은 라인 · 애플 · 구글. 글자가 든 그림(타이틀 · 애플 · 구글)은
/// 같은 이름으로 `ja/`에 일본어판이 있다(`DesignCanvas.localizedAssets`).
/// 카카오와 라인은 **언어 변형이 아니라 나라마다 다른 버튼**이라 국기처럼 전달 이름 그대로 둔다
/// (`button_kakao_kr.png` · `button_line_jp.png` — 대조 도구 `COUNTRY_PREFIXES`).
abstract final class TitleArt {
  static const _dir = 'assets/images/scene_login/title';

  /// 배경(1080×2640, 글자 없음 — 두 나라 공용).
  static const background = '$_dir/back_main_login.png';

  /// `달빛톡` / 「月あかりトーク」 — 한국어 512×224, 일본어 652×197.
  static const title = '$_dir/title_appmain.png';
  static const titleSize = Size(512, 224);
  static const titleSizeJa = Size(652, 197);

  /// 타이틀 왼쪽 위 — 한국어 295 · 일본어 211(가운데 정렬 값).
  /// ⚠️ 좌표 시안의 한국어 *"29, 796"* 은 *"295"* 의 오타로 본다(자동 로그인 시안이 295, 512폭 가운데가 284).
  static double titleLeft(bool ja) => ja ? 211 : 295;

  /// [로그인 선택] 상태의 타이틀 윗변(두 나라 같다).
  static const titleTopLogin = 796.0;

  /// [자동 로그인] 상태(저장된 토큰을 확인하는 동안) — 버튼 없이 타이틀만 가운데에.
  static double titleTopAuto(bool ja) => ja ? 1323 : 1297;

  static const buttonKakao = '$_dir/button_kakao_kr.png'; // 780×137, 한국만
  static const buttonLine = '$_dir/button_line_jp.png'; // 780×142, 일본만
  static const buttonApple = '$_dir/button_apple.png'; // 780×136, 한·일
  static const buttonGoogle = '$_dir/button_google.png'; // 780×136, 한·일

  static const buttonLeft = 148.0;
  static const buttonWidth = 780.0;

  /// 버튼 세 칸의 윗변(시안 148,1182 · 148,1374 · 148,1567).
  static const buttonTops = [1182.0, 1374.0, 1567.0];

  /// 아래 안내(`로그인 방법을 선택해 주세요`)의 윗변 — 글자(폰트)다.
  static const noticeTop = 2486.0;
}

/// 타이틀 화면의 **판** — 1080×2640 시안을 화면에 `cover`로 맞추고(넘치는 쪽은 가운데를 남기고 자른다),
/// 그 위에 시안 좌표 그대로 얹는다. 고정 화면이라 스크롤하지 않는다(공통 규칙 §5).
///
/// [builder]는 시안 좌표 → 화면 좌표 변환기([TitlePlace])를 받아 `Positioned` 목록을 돌려준다.
class TitleFrame extends StatelessWidget {
  const TitleFrame({super.key, required this.builder});

  final List<Widget> Function(BuildContext context, TitlePlace place) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final place = TitlePlace(box.biggest);
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              TitleArt.background,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
            ),
            ...builder(context, place),
          ],
        );
      },
    );
  }
}

/// 시안 좌표(1080×2640) → 화면 좌표. 배경이 `cover` + 가운데 정렬로 그려지는 것과 **같은 셈**이다.
class TitlePlace {
  TitlePlace(this.screen)
    : scale = (screen.width / DesignCanvas.width) > (screen.height / DesignCanvas.height)
          ? screen.width / DesignCanvas.width
          : screen.height / DesignCanvas.height;

  final Size screen;

  /// 시안 1px → 화면 논리px.
  final double scale;

  double get _dx => (DesignCanvas.width * scale - screen.width) / 2;
  double get _dy => (DesignCanvas.height * scale - screen.height) / 2;

  double x(double designX) => designX * scale - _dx;
  double y(double designY) => designY * scale - _dy;

  /// 시안 좌표에 그림 한 장을 얹는다.
  Widget art(
    String asset, {
    required double left,
    required double top,
    required Size size,
  }) => Positioned(
    left: x(left),
    top: y(top),
    child: ArtImage(asset, width: size.width, height: size.height, scale: scale),
  );
}
