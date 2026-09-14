import 'package:flutter/material.dart';

/// 오늘의 포스트 화면 리소스(Plan_4). 경로와 **시안 원본 규격**만 모아 둔다.
///
/// 규격을 상수로 들고 있는 이유는 [ArtImage]가 원본 크기를 받아 화면 폭에 맞춰
/// 줄여 그리기 때문이다 — **일본어판 이미지로 교체할 때 같은 규격이면 코드를 안 고쳐도 된다.**
///
/// 좌표는 `오늘의 포스트 좌표값.png`의 1080 캔버스 픽셀값이다(Plan_4부터 단위 변환이 없다).
class PostArt {
  const PostArt._();

  /// 전달 폴더(`Plan_Chat/UI/Scene_Post`)와 **같은 이름·같은 구조**다.
  static const String _dir = 'assets/images/scene_post';

  /// 🚨 **포스트 전용이 아니다.** Prime·루나·하트·말풍선처럼 여러 화면이 함께 쓰는 그림은
  /// 달빛가든 쪽으로 전달됐다 — 받은 자리를 그대로 두고 여기서 가리킨다.
  static const String _garden = 'assets/images/scene_garden';

  /// 화면 배경. 상단 밤 풍경이 그려져 있다.
  static const String background = '$_dir/back_post.png';

  /// 사진을 아직 안 올렸을 때 카드 안을 채우는 그림.
  static const String emptyBackground = '$_dir/back_nopost.png';
  static const Size emptySize = Size(1022, 1790);

  static const String title = '$_dir/title_post.png';
  static const Size titleSize = Size(232, 66);
  static const Offset titleAt = Offset(47, 106);

  // 상단 우측 두 버튼 — 달빛가든과 같은 자리·같은 그림이라 common에 둔다.
  static const String btnPrime = '$_garden/button_prime.png';
  static const Size btnPrimeSize = Size(248, 83);
  static const Offset btnPrimeAt = Offset(577, 102);

  static const String btnLuna = '$_garden/button_luna.png';
  static const Size btnLunaSize = Size(216, 83);
  static const Offset btnLunaAt = Offset(838, 102);

  // 카드 위 두 버튼.
  static const String btnAlbumPass = '$_dir/button_postalbum.png';
  static const Size btnAlbumPassSize = Size(601, 96);
  static const Offset btnAlbumPassAt = Offset(23, 356);

  static const String btnBoost = '$_dir/button_boost.png';
  static const Size btnBoostSize = Size(407, 96);
  static const Offset btnBoostAt = Offset(645, 356);

  /// 두 버튼의 그림에는 `포스트 앨범 |` · `부스트 |` 까지만 있다.
  /// **막대 오른쪽은 비어 있고** 거기에 상태(남은 일수·남은 분·구매)를 얹는다 —
  /// 사람마다 다른 값이라 그림에 구울 수 없다.
  static const double btnAlbumPassStatusLeft = 370;
  static const double btnBoostStatusLeft = 260;

  // 카드 안에 얹히는 것들.
  //
  // ⚠️ **세로 위치는 시안 값을 그대로 쓰지 않는다.** 카드가 화면 높이에 따라 늘어나기 때문이다
  // (기기마다 세로 비율이 달라 1080×2640을 그대로 옮기면 아래가 잘리거나 남는다).
  // 가로 위치·크기만 시안을 따르고, 세로는 카드의 위/아래에 붙인다.
  static const String btnTopOn = '$_dir/button_mainpost_color.png';
  static const String btnTopOff = '$_dir/button_mainpost_normal.png';
  static const Size btnTopSize = Size(244, 84);

  static const String badgePick = '$_dir/icon_pick.png';
  static const Size badgePickSize = Size(144, 71);

  static const String btnDelete = '$_dir/button_delete.png';
  static const Size btnDeleteSize = Size(105, 101);

  static const String btnShare = '$_dir/button_postmake.png';
  static const Size btnShareSize = Size(418, 103);

  /// 카드 윗변(시안 `23, 475`의 y).
  ///
  /// ⚠️ 위에 쌓인 높이를 셀 때 **타이틀이 아니라 Prime 버튼**이 머리글 줄 높이를 정한다
  /// (Row라 가장 큰 요소가 이긴다). 계산은 `DesignCanvas.aboveCard()`가 한다.
  ///
  /// 카드 **높이**는 시안 값(1797)을 쓰지 않는다. 화면 세로가 기기마다 달라
  /// 그대로 쓰면 넘치거나 남는다 — 남은 공간을 카드가 채우게 한다.
  static const double cardTop = 475;

  /// 두 버튼 아랫변 → 카드 윗변.
  static double get buttonsToCard =>
      cardTop - (btnAlbumPassAt.dy + btnAlbumPassSize.height);

  /// 카드 안 요소들의 **카드 바닥 기준** 위치(시안 원본 픽셀).
  ///
  /// 세로를 카드 윗변이 아니라 **아랫변 기준으로** 잡는 이유 — 카드 높이가 기기마다
  /// 달라지기 때문이다. 윗변 기준으로 두면 화면이 짧을 때 아래로 밀려 잘린다.
  /// (카드 바닥 = 시안 2272)
  static const double _cardBottom = 2272;

  /// 촬영 버튼 윗변(시안 `441, 1838`).
  static const double _cameraTop = 1838;

  /// 촬영 버튼 아랫변 — **그림 높이에서 계산한다.**
  /// 예전엔 코드로 그리던 지름(164)을 더해 굳혀 뒀는데, 그림(188)으로 오면서 값이 어긋났다.
  static double get cameraBottom =>
      _cardBottom - (_cameraTop + btnCameraSize.height);

  /// 좋아요·공유 줄의 아랫변(시안에서 둘 다 ≈2201).
  static const double bottomRowBottom = _cardBottom - 2201;

  /// 카드 안쪽 좌우 여백 — 하트가 시안 64, 카드 왼쪽이 23이므로 41이다.
  static const double cardSidePad = 41;

  /// 촬영 버튼 — 시안 `441, 1838`.
  ///
  /// ✅ **이제 그림으로 온다**(2026-09-14 전달본). 예전에는 무지개 링을 코드로 그렸는데,
  /// 실물은 링의 색 배치와 안쪽 검정 원까지 있어 코드로 흉내 내던 것과 다르다.
  static const String btnCamera = '$_dir/button_camera.png';
  static const Size btnCameraSize = Size(193, 188);
}
