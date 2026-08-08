import 'package:flutter/material.dart';

/// 달빛가든 리소스(Plan_3) — 기획이 준 PNG를 그대로 쓰기 위한 배치 도구.
///
/// **이 앱의 UI 언어는 두 종류다.**
/// 1. **폰트** — ARB(`app_ko.arb`/`app_ja.arb`)가 그리는 글자. 언어가 바뀌면 따라 바뀐다.
/// 2. **이미지** — 아래 에셋처럼 그림에 글자가 **구워져 있는 것**. 폰트로 대체하지 않는다.
///    일본어판은 **일본어가 박힌 이미지를 따로** 받아 교체한다(같은 파일명, `ja/` 폴더 등).
/// 그래서 여기 있는 한글은 "덜 옮긴 것"이 아니라 **의도된 상태**다.
///
/// 좌표·크기는 기획 시안(`달빛가든 화면 이미지 좌표.png`)의 **1080×2640 캔버스** 기준이다.
/// 시안의 빨간 숫자는 `X*Y` 쌍이고 **1 단위 ≈ 28.4px**(요소의 좌상단 기준).
/// 예) 필터 바 `0.95*12.58` → (27px, 357px).
class GardenArt {
  const GardenArt._();

  static const String _dir = 'assets/images/garden';

  static const String background = '$_dir/garden_bg.png';
  static const String title = '$_dir/title_garden.png';
  static const String btnPrime = '$_dir/btn_prime.png';
  static const String btnLuna = '$_dir/btn_luna.png';
  // 필터 칩 — 값마다 라벨이 구워진 그림이 따로 있다(전체 포함).
  // 그룹 안에서는 규격이 같아 크기를 한 번만 적으면 된다.
  static const String filterGenderAll = '$_dir/filter_gender_all.png';
  static const String filterFemale = '$_dir/filter_female.png';
  static const String filterMale = '$_dir/filter_male.png';
  static const String filterAgeAll = '$_dir/filter_age_all.png';
  static const String filter10s = '$_dir/filter_10s.png';
  static const String filter20s = '$_dir/filter_20s.png';
  static const String filter30s = '$_dir/filter_30s.png';
  static const String filter40s = '$_dir/filter_40s.png';
  static const String filterCountryAll = '$_dir/filter_country_all.png';
  static const String filterKorea = '$_dir/filter_korea.png';
  static const String filterJapan = '$_dir/filter_japan.png';
  static const String filterSpotlight = '$_dir/filter_spotlight.png';

  /// 필터 칩 원본 규격(1080 캔버스 기준).
  static const Size filterGenderSize = Size(217, 94);
  static const Size filterAgeSize = Size(227, 94);
  static const Size filterCountrySize = Size(208, 95);
  static const Size filterSpotlightSize = Size(334, 94);

  /// 값 → 그림. 이제 모든 상태에 그림이 있어 텍스트 폴백이 필요 없다.
  static String genderChip(String? gender) => switch (gender) {
    'FEMALE' => filterFemale,
    'MALE' => filterMale,
    _ => filterGenderAll,
  };

  static String ageChip(int? decade) => switch (decade) {
    10 => filter10s,
    20 => filter20s,
    30 => filter30s,
    40 => filter40s,
    _ => filterAgeAll,
  };

  static String countryChip(String? country) => switch (country) {
    'KR' => filterKorea,
    'JP' => filterJapan,
    _ => filterCountryAll,
  };
  static const String cardFrame = '$_dir/card_frame.png';
  static const String flagKr = '$_dir/flag_kr.png';
  static const String badgePick = '$_dir/badge_pick.png';
  static const String interestMovie = '$_dir/interest_movie.png';
  static const String iconHeart = '$_dir/icon_heart.png';
  static const String iconComment = '$_dir/icon_comment.png';
  static const String btnChatRequest = '$_dir/btn_chat_request.png';

  /// 시안 캔버스 폭. 에셋의 원본 픽셀이 이 폭을 전제로 그려져 있다.
  static const double canvasWidth = 1080;

  /// 카드(사진) 영역의 라운드. 외곽선 그림이 가진 곡률과 맞춰야 한다 —
  /// 값이 다르면 클립이 프레임 모서리를 잘라 각이 깎여 보인다.
  static const double cardCornerRadius = 24;

  /// 외곽선을 9-슬라이스로 늘리기 위한 중앙 영역(원본 1029×1794 기준).
  ///
  /// 카드 영역의 가로세로 비가 원본과 달라 그냥 늘이면 모서리 곡률이 찌그러진다.
  /// 네 모서리는 원본 크기로 두고 **가운데만** 늘리려고 이 사각형을 준다.
  /// 값은 모서리 라운드(≈60px)보다 넉넉히 잡았다.
  static const Rect cardFrameCenterSlice = Rect.fromLTRB(90, 90, 939, 1704);

  /// 시안 좌표 1단위의 픽셀 크기(캔버스 기준).
  static const double unit = 28.4;

  /// 화면 폭에 맞춘 배율. 폭이 좁은 기기에서도 시안 비율이 유지된다.
  static double scaleOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width / canvasWidth;
}

/// 시안 원본 픽셀 크기를 그대로 적어 두고, 화면 폭에 맞춰 줄여 그리는 이미지.
///
/// 크기를 하드코딩하지 않고 원본 값을 쓰는 이유 — 나중에 **일본어판 이미지로 교체**할 때
/// 같은 규격이면 코드를 손대지 않아도 되기 때문이다.
class ArtImage extends StatelessWidget {
  const ArtImage(
    this.asset, {
    required this.width,
    required this.height,
    this.opacity = 1.0,
    super.key,
  });

  /// 시안 원본 픽셀(1080 캔버스 기준).
  final double width;
  final double height;
  final String asset;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final s = GardenArt.scaleOf(context);
    final image = Image.asset(
      asset,
      width: width * s,
      height: height * s,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
    return opacity == 1.0 ? image : Opacity(opacity: opacity, child: image);
  }
}
