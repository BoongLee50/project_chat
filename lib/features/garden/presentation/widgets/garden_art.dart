import 'package:flutter/material.dart';

/// 달빛가든 리소스 — 경로와 **시안 원본 규격**만 모아 둔다.
///
/// 전달 폴더(`Plan_Chat/UI/Scene_Garden`)와 **같은 이름·같은 구조**다.
/// 다음 전달본을 그대로 떨어뜨리면 되도록 이름을 바꾸지 않는다.
///
/// 🚨 **여기 있는 그림이 달빛가든 전용은 아니다.** 하단 주메뉴·Prime·루나·하트·말풍선은
/// 모든 화면이 함께 쓰는데 이 폴더로 전달됐다 — 받은 자리를 그대로 두고 각자 가리킨다.
///
/// **UI 언어는 두 종류다**(docs/14 §2) — 폰트(ARB)와 **글자가 구워진 그림**.
/// 아래 한글은 "덜 옮긴 것"이 아니라 의도된 상태이고, 일본어판은 같은 이름으로 `ja/`에 둔다.
///
/// 좌표는 `달빛가든 UI 좌표값.png`의 **1080×2640 캔버스 픽셀값을 그대로** 쓴다.
class GardenArt {
  const GardenArt._();

  static const String _dir = 'assets/images/scene_garden';

  static const String background = '$_dir/back_garden.png';

  static const String title = '$_dir/title_garden.png';
  static const Size titleSize = Size(278, 71);
  static const Offset titleAt = Offset(47, 106);

  // 상단 우측 두 버튼 — 오늘의 포스트와 같은 자리·같은 그림이다.
  static const String btnPrime = '$_dir/button_prime.png';
  static const Size btnPrimeSize = Size(248, 83);
  static const Offset btnPrimeAt = Offset(577, 102);

  static const String btnLuna = '$_dir/button_luna.png';
  static const Size btnLunaSize = Size(216, 83);
  static const Offset btnLunaAt = Offset(838, 102);

  // ── 필터 줄 — 네 칸이다(성별·나이·국가 + 달빛 한마디) ─────────────
  //
  // ✅ **2026-09-14 전달본에서 "값마다 그림" 방식으로 돌아왔다.**
  // 한동안은 라벨 한 장만 받아 고른 값을 **폰트로 덮어 그렸는데**, 이제 값마다
  // 그림이 와서 그럴 필요가 없다 — 칩 전체가 한 장이라 아이콘까지 값에 맞게 바뀐다
  // (`여자`면 여성 아이콘, `한국`이면 태극기). 폰트로는 못 하던 것이다.
  //
  // 🚨 **그림이 있는 값만 고를 수 있다.** 아래 표에 없는 값을 화면이 만들면 칩이 비어 보인다 —
  // 값을 늘리려면 **그림을 먼저 받아야 한다**(docs/14 §4).
  static const String filterGender = '$_dir/filtering_gender.png';
  static const Size filterGenderSize = Size(217, 92);
  static const Offset filterGenderAt = Offset(23, 356);

  /// 성별 값 → 칩 그림. 키는 서버 코드다(문구가 아니라 코드로 잡는다).
  static const Map<String, String> filterGenderByValue = {
    'FEMALE': '$_dir/filtering_gender_female.png',
    'MALE': '$_dir/filtering_gender_man.png',
  };

  static const String filterAge = '$_dir/filtering_age.png';
  static const Size filterAgeSize = Size(227, 94);
  static const Offset filterAgeAt = Offset(257, 355);

  /// 나이대 값 → 칩 그림.
  static const Map<int, String> filterAgeByValue = {
    10: '$_dir/filtering_age10.png',
    20: '$_dir/filtering_age20.png',
    30: '$_dir/filtering_age30.png',
    40: '$_dir/filtering_age40.png',
  };

  static const String filterCountry = '$_dir/filtering_nation.png';
  static const Size filterCountrySize = Size(217, 94);
  static const Offset filterCountryAt = Offset(494, 356);

  /// 국가 값 → 칩 그림.
  ///
  /// ⚠️ `_kor`/`_jap`은 **UI 언어가 아니라 고른 나라**다 — 둘 다 항상 필요하다.
  /// (글자는 아직 한국어라 일본어판이 따로 있어야 한다 — docs/08 §0-1)
  static const Map<String, String> filterCountryByValue = {
    'KR': '$_dir/filtering_nation_kor.png',
    'JP': '$_dir/filtering_nation_jap.png',
  };

  static const String btnDailyQuestion = '$_dir/button_Moonlight.png';
  static const Size btnDailyQuestionSize = Size(335, 96);
  static const Offset btnDailyQuestionAt = Offset(724, 356);

  /// 카드 윗변(시안 `23, 475`의 y) — **포스트 화면과 같은 값**이다.
  /// 두 화면의 카드가 같은 자리·같은 폭이라 하단 주메뉴와도 선이 맞는다.
  static const double cardTop = 475;

  /// 필터 줄 아랫변 → 카드 윗변.
  static double get filtersToCard =>
      cardTop - (filterGenderAt.dy + filterGenderSize.height);

  // ── 카드 안 ────────────────────────────────────────────
  /// 상대의 **국적** 국기. 언어 변형이 아니라 내용이라 둘 다 쓴다.
  static const String flagKr = '$_dir/icon_flag_kor.png';
  static const String flagJp = '$_dir/icon_flag_jap.png';
  static const Size flagSize = Size(70, 70);

  /// 국가 코드 → 국기. 모르는 코드면 null(국기를 그리지 않는다).
  static String? flagOf(String? country) => switch (country) {
        'KR' => flagKr,
        'JP' => flagJp,
        _ => null,
      };

  static const String badgePick = '$_dir/button_Pick.png';
  static const Size badgePickSize = Size(144, 71);

  static const String interestMovie = '$_dir/Interest_movie.png';
  static const Size interestSize = Size(204, 89);

  static const String iconHeart = '$_dir/button_heart.png';
  static const Size iconHeartSize = Size(72, 67);

  static const String iconComment = '$_dir/button_comment.png';
  static const Size iconCommentSize = Size(71, 71);

  static const String btnChatRequest = '$_dir/button_conversation.png';
  static const Size btnChatRequestSize = Size(144, 145);

  /// 카드 안 `새 사진 등록하기` 버튼(시안 `288, 1674`).
  /// ✅ 2026-09-14 전달본에서 그림으로 왔다 — 전에는 코드로 그렸다.
  static const String btnAddPost = '$_dir/button_addpost.png';
  static const Size btnAddPostSize = Size(499, 116);

  /// 카드(사진) 영역의 라운드 — 외곽선 시안의 곡률에 맞춘 값이다.
  static const double cardCornerRadius = 30;

  /// 카드 외곽선 **그림**.
  ///
  /// 🚨 **두 그림의 여백이 다르다 — 그대로 채우면 사진과 선이 어긋난다.**
  /// 실측(알파 채널):
  /// - `frame_post_common.png` 1032×1797 — 선이 **이미지 가장자리에 딱 붙어 있다**(여백 0).
  /// - `frame_post_album_pass.png` 1053×1817 — 발광이 번져 **선이 사방 6~8px 안쪽**이다.
  ///
  /// 둘을 같은 상자에 `BoxFit.fill`로 채우면 패스 쪽만 선이 안으로 들어가고,
  /// 사진은 상자 경계까지 그려져 **밖으로 삐져나온다.**
  /// → 패스 그림은 여백만큼 **상자 밖으로 넓혀** 그린다([framePadding]).
  static const String cardFrame = '$_dir/frame_post_common.png';
  static const Size cardFrameSize = Size(1032, 1797);

  static const String cardFramePass = '$_dir/frame_post_album_pass.png';
  static const Size cardFramePassSize = Size(1053, 1817);

  /// 그림 안에서 **선이 차지하는 영역**(좌, 상, 우, 하 여백). 실측값이다.
  static const EdgeInsets framePadding = EdgeInsets.zero;
  static const EdgeInsets framePassPadding = EdgeInsets.fromLTRB(8, 6, 8, 8);

  /// 선 영역의 크기 — 이 크기가 카드와 일치해야 한다.
  static Size get frameLineSize => cardFrameSize;
  static Size get framePassLineSize => Size(
        cardFramePassSize.width - framePassPadding.horizontal,
        cardFramePassSize.height - framePassPadding.vertical,
      );

  /// 외곽선의 **모서리 반경**(실측 ≈24). 사진을 이 값으로 잘라야 선과 맞물린다.
  static const double frameCornerRadius = 24;

  /// 선 **두께**(실측, 알파 채널 기준). 사진을 이만큼 안으로 밀어 넣으면
  /// 계산이 조금 어긋나도 **선 밖으로 나갈 수 없다**.
  /// 패스 쪽이 두꺼운 건 발광이 함께 잡히기 때문이다.
  static const double frameLineWidth = 7;
  static const double framePassLineWidth = 13;
}
