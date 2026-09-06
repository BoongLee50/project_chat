import 'package:flutter/material.dart';

/// 달빛가든 리소스(Plan_4) — 경로와 **시안 원본 규격**만 모아 둔다.
///
/// **이 앱의 UI 언어는 두 종류다.**
/// 1. **폰트** — ARB(`app_ko.arb`/`app_ja.arb`)가 그리는 글자. 언어가 바뀌면 따라 바뀐다.
/// 2. **이미지** — 아래 에셋처럼 그림에 글자가 **구워져 있는 것**. 폰트로 대체하지 않는다.
///    일본어판은 **일본어가 박힌 이미지를 따로** 받아 교체한다(같은 규격, `ja/` 폴더 등).
/// 그래서 여기 있는 한글은 "덜 옮긴 것"이 아니라 **의도된 상태**다.
///
/// 좌표는 `달빛가든 화면_좌표값.png`의 **1080×2640 캔버스 픽셀값을 그대로** 쓴다.
/// ⚠️ 같은 폴더의 `달빛가든 화면_참고용.png`는 **Plan_3 시절**이라 `X*Y` 단위(×28.4) 표기다 —
/// 둘을 섞어 읽지 말 것.
class GardenArt {
  const GardenArt._();

  static const String _dir = 'assets/images/garden';
  static const String _common = 'assets/images/common';

  static const String background = '$_dir/garden_bg.png';

  static const String title = '$_dir/title_garden.png';
  static const Size titleSize = Size(278, 71);
  static const Offset titleAt = Offset(47, 106);

  // 상단 우측 두 버튼 — 오늘의 포스트와 같은 자리·같은 그림이라 common에 둔다.
  static const String btnPrime = '$_common/btn_prime.png';
  static const Size btnPrimeSize = Size(248, 83);
  static const Offset btnPrimeAt = Offset(577, 102);

  static const String btnLuna = '$_common/btn_luna.png';
  static const Size btnLunaSize = Size(216, 83);
  static const Offset btnLunaAt = Offset(838, 102);

  // ── 필터 줄 — 네 칸이다(성별·나이·국가 + 달빛 한마디) ─────────────
  //
  // ⚠️ **Plan_4에서 구조가 바뀌었다.** 전에는 값마다 그림이 따로 있었지만
  // (`filter_female`·`filter_20s`…), 이제 **라벨 한 장씩**만 온다.
  // 고른 값은 그림 위에 **폰트로 얹는다** — 그래야 값이 늘어도 그림을 새로 안 받는다.
  static const String filterGender = '$_dir/filter_gender.png';
  static const Size filterGenderSize = Size(217, 92);
  static const Offset filterGenderAt = Offset(23, 356);

  static const String filterAge = '$_dir/filter_age.png';
  static const Size filterAgeSize = Size(227, 94);
  static const Offset filterAgeAt = Offset(257, 355);

  static const String filterCountry = '$_dir/filter_country.png';
  static const Size filterCountrySize = Size(217, 94);
  static const Offset filterCountryAt = Offset(494, 356);

  static const String btnDailyQuestion = '$_dir/btn_daily_question.png';
  static const Size btnDailyQuestionSize = Size(330, 94);
  static const Offset btnDailyQuestionAt = Offset(724, 356);

  /// 칩의 **글자 영역 시작** — 아이콘을 뺀 오른쪽 부분이다.
  /// 고른 값을 여기에 덮어 그린다(그림에는 `성별`·`나이`·`국가`가 구워져 있다).
  static const double filterLabelLeft = 92;

  /// 칩 안쪽 색. 그림의 내부가 **불투명 검정**이라 같은 색으로 덮으면 이어져 보인다.
  /// (반투명이었다면 이 방식을 못 쓴다 — 덮은 자리만 색이 달라진다)
  static const Color filterChipFill = Color(0xFF000000);

  // ── 카드 안 ────────────────────────────────────────────
  static const String flagKr = '$_dir/flag_kr.png';
  static const Size flagSize = Size(70, 71);

  static const String badgePick = '$_common/badge_pick.png';
  static const Size badgePickSize = Size(144, 71);

  static const String interestMovie = '$_dir/interest_movie.png';
  static const Size interestSize = Size(204, 89);

  static const String iconHeart = '$_dir/icon_heart.png';
  static const Size iconHeartSize = Size(72, 67);

  static const String iconComment = '$_dir/icon_comment.png';
  static const Size iconCommentSize = Size(71, 71);

  static const String btnChatRequest = '$_dir/btn_chat_request.png';
  static const Size btnChatRequestSize = Size(144, 145);

  /// 카드(사진) 영역의 라운드 — Plan_4 외곽선 시안의 곡률에 맞춘 값이다.
  static const double cardCornerRadius = 30;

  /// 카드 외곽선 — **그림을 받았지만 쓰지 않고 코드로 그린다.**
  ///
  /// Plan_4에 `포스트 외곽선_일반/앨범패스` 두 장이 왔는데, 열어 보니 둘 다
  /// **얇은 선 하나**다(일반=흰 선, 앨범패스=무지개 그러데이션 선). 질감이 없다.
  ///
  /// 카드 높이는 기기마다 달라 원본 비율(1032×1797)과 어긋나므로, 그림을 늘이면
  /// **선 굵기와 모서리 곡률이 찌그러진다**(함정 #31 — 실제로 한 번 겪었다).
  /// 코드로 그리면 어떤 크기에서도 굵기가 일정하고 모서리가 깨끗하다.
  /// 발광 질감이 있었다면 그림을 썼겠지만, 이건 선이라 코드가 낫다.
  ///
  /// 앨범 패스·프라임을 가진 사람의 포스트에는 무지개 쪽이 붙는다(기획 화면 26·29) —
  /// 산 사람의 포스트가 한눈에 달라 보여야 파는 값이 생긴다.
  static const double cardBorderWidth = 1.6;
  static const Color cardBorderColor = Color(0xB3FFFFFF);

  /// 무지개 외곽선 — 시안(`포스트 외곽선_앨범패스`)의 색 순서를 그대로 옮겼다.
  /// 좌상단 자홍 → 우상단 주황 → 우하단 적분홍 → 좌하단 파랑 → 다시 자홍.
  static const double decoratedBorderWidth = 2.6;
  static const List<Color> decoratedBorderColors = [
    Color(0xFFD62BFF),
    Color(0xFFFF8A2B),
    Color(0xFFFF2B6B),
    Color(0xFF2B6BFF),
    Color(0xFFD62BFF),
  ];
}
