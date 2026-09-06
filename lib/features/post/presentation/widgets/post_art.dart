import 'package:flutter/material.dart';

/// 오늘의 포스트 화면 리소스(Plan_4). 경로와 **시안 원본 규격**만 모아 둔다.
///
/// 규격을 상수로 들고 있는 이유는 [ArtImage]가 원본 크기를 받아 화면 폭에 맞춰
/// 줄여 그리기 때문이다 — **일본어판 이미지로 교체할 때 같은 규격이면 코드를 안 고쳐도 된다.**
///
/// 좌표는 `오늘의 포스트 좌표값.png`의 1080 캔버스 픽셀값이다(Plan_4부터 단위 변환이 없다).
class PostArt {
  const PostArt._();

  static const String _dir = 'assets/images/post';
  static const String _common = 'assets/images/common';

  /// 화면 배경. 상단 밤 풍경이 그려져 있다.
  static const String background = '$_dir/post_bg.png';

  /// 사진을 아직 안 올렸을 때 카드 안을 채우는 그림.
  static const String emptyBackground = '$_dir/empty_bg.png';
  static const Size emptySize = Size(1022, 1790);

  static const String title = '$_dir/title_post.png';
  static const Size titleSize = Size(232, 66);
  static const Offset titleAt = Offset(47, 106);

  // 상단 우측 두 버튼 — 달빛가든과 같은 자리·같은 그림이라 common에 둔다.
  static const String btnPrime = '$_common/btn_prime.png';
  static const Size btnPrimeSize = Size(248, 83);
  static const Offset btnPrimeAt = Offset(577, 102);

  static const String btnLuna = '$_common/btn_luna.png';
  static const Size btnLunaSize = Size(216, 83);
  static const Offset btnLunaAt = Offset(838, 102);

  // 카드 위 두 버튼.
  static const String btnAlbumPass = '$_dir/btn_album_pass.png';
  static const Size btnAlbumPassSize = Size(601, 96);
  static const Offset btnAlbumPassAt = Offset(23, 356);

  static const String btnBoost = '$_dir/btn_boost.png';
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
  static const String btnTopOn = '$_dir/btn_top_on.png';
  static const String btnTopOff = '$_dir/btn_top_off.png';
  static const Size btnTopSize = Size(244, 84);

  static const String badgePick = '$_common/badge_pick.png';
  static const Size badgePickSize = Size(144, 71);

  static const String btnDelete = '$_dir/btn_delete.png';
  static const Size btnDeleteSize = Size(105, 101);

  static const String btnShare = '$_dir/btn_share.png';
  static const Size btnShareSize = Size(418, 103);

  /// 촬영 버튼은 그림으로 오지 않았다 — 무지개 링 + 흰 카메라라 코드로 그린다.
  /// 시안 `441, 1838` 자리이고 지름은 약 164다.
  static const double cameraSize = 164;
  static const List<Color> cameraRing = [
    Color(0xFF7B5CFF),
    Color(0xFFFF4FA3),
    Color(0xFFFFB03A),
    Color(0xFF7B5CFF),
  ];
}
