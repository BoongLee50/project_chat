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

  /// 필터 칩 원본 규격(1080 캔버스 기준).
  static const Size filterGenderSize = Size(217, 94);
  static const Size filterAgeSize = Size(227, 94);
  static const Size filterCountrySize = Size(208, 95);

  /// 칩 사이 간격(시안 원본 기준). 시안에서 칩 끝과 다음 칩 시작 사이가 13~15px이다.
  static const double filterGap = 14;

  /// 달빛 한마디 진입 버튼의 규격(시안 4-1의 **네 번째 칸**).
  ///
  /// Plan_3에서 스포트라이트 칩이 폐지된 자리에 **같은 크기로** 달빛 한마디 버튼이 들어간다.
  /// 드롭다운 칩이 아니라 **채워진 버튼**이고, 누르면 오늘의 질문 화면으로 간다.
  /// 아직 리소스도 화면도 없어 그리지 않지만, **자리는 이 상수만큼 비워 둔다**(⑤단계에서 채운다).
  static const Size filterDailyQuestionSize = Size(334, 94);

  /// 필터 칩 줄의 배율.
  ///
  /// 시안은 **네 칸**이 한 줄에 딱 맞는다 — 성별·나이·국가 칩 셋과 **달빛 한마디 버튼**.
  /// 네 칸 기준으로 배율을 구하므로, 버튼을 아직 안 그려도 **칩 셋의 크기가 시안과 같고
  /// 오른쪽에 버튼 자리만큼 여백이 남는다.** ⑤단계에서 버튼을 채우면 레이아웃은 그대로다.
  ///
  /// (셋 기준으로 계산하면 남는 폭을 셋이 나눠 가져 **칩이 1.5배로 부푼다** — 함정 #37)
  static double filterRowScale(double availableWidth) {
    const designTotal = 217 + 227 + 208 + 334 + filterGap * 3; // 네 칸 + 간격 3개
    return availableWidth / designTotal;
  }

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
  static const String flagKr = '$_dir/flag_kr.png';
  static const String badgePick = '$_dir/badge_pick.png';
  static const String interestMovie = '$_dir/interest_movie.png';
  static const String iconHeart = '$_dir/icon_heart.png';
  static const String iconComment = '$_dir/icon_comment.png';
  static const String btnChatRequest = '$_dir/btn_chat_request.png';

  /// 시안 캔버스 폭. 에셋의 원본 픽셀이 이 폭을 전제로 그려져 있다.
  static const double canvasWidth = 1080;

  /// 카드(사진) 영역의 라운드.
  static const double cardCornerRadius = 24;

  /// 카드 테두리 — **이미지가 아니라 코드로 그린다.**
  ///
  /// `포스트 사진 외곽선.png`는 단순한 얇은 라운드 사각 외곽선이라 그림일 필요가 없다.
  /// 오히려 이미지로 쓰면 손해다:
  /// - 카드 크기·비율이 기기마다 달라 늘이면 **선 굵기와 모서리 곡률이 찌그러진다**
  /// - 래스터라 확대되면 **뿌옇게 번진다**
  /// 코드로 그리면 어떤 크기에서도 선 굵기가 일정하고 모서리가 깨끗하다.
  ///
  /// (글자·질감이 들어간 리소스는 그림을 그대로 쓴다 — 이건 선 하나뿐이라 예외다)
  static const double cardBorderWidth = 1.4;
  static const Color cardBorderColor = Color(0xCCFFFFFF);

  /// **꾸미기 외곽선** — 앨범 패스·프라임을 가진 사람의 포스트에 붙는다
  /// (기획 화면 26·29 "포스트 사진 꾸미기 외곽선 적용" · "무지개빛 테두리 효과").
  ///
  /// 산 사람의 포스트가 **한눈에 달라 보여야** 파는 값이 생기므로 굵기도 함께 키운다.
  /// 그림이 아니라 코드로 그리는 이유는 위 주석과 같다 — 크기가 기기마다 달라서다.
  static const double decoratedBorderWidth = 3.0;
  static const List<Color> decoratedBorderColors = [
    Color(0xFFFF6B9D),
    Color(0xFFFFD24C),
    Color(0xFF7BE8A8),
    Color(0xFF6EC7FF),
    Color(0xFF8B7CF6),
    Color(0xFFFF6B9D),
  ];

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
    this.scale,
    this.opacity = 1.0,
    super.key,
  });

  /// 시안 원본 픽셀(1080 캔버스 기준).
  final double width;
  final double height;
  final String asset;

  /// 배율을 직접 줄 때 사용. 없으면 화면 폭 기준([GardenArt.scaleOf]).
  /// 필터 바처럼 **주어진 폭에 딱 맞춰야** 하는 곳에서 계산한 값을 넘긴다.
  final double? scale;

  final double opacity;

  @override
  Widget build(BuildContext context) {
    final s = scale ?? GardenArt.scaleOf(context);
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
