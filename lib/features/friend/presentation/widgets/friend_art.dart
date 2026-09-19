import 'package:flutter/material.dart';

import '../../../chat/presentation/widgets/talk_art.dart';

/// 친구 화면 리소스(`Plan_Chat/UI/Scene_Friend`, 2026-09-19 전달본). 경로와 **시안 원본 규격**만 모은다.
///
/// 좌표는 `친구방_친구목록 좌표값.png` · `친구방_친구목록_포스트 팝업창 좌표.png` ·
/// `친구방_받은신청_팝업창 좌표.png`의 **1080 캔버스 픽셀값**이다.
///
/// 📌 **대화방과 같은 자리·같은 그림이 많다.** 탭 위치와 빨간 점, [받은 신청] 셀, 팝업의 테두리·
/// 흰 패널·`[원문보기]`·`[프로필]`·`[✕]`·`[💬]`는 대화방 것(`TalkArt`)을 그대로 쓴다 —
/// 기획서 7-2 *"[받은 신청]의 화면 구성과 기능은 [대화 목록]창과 동일"*. 여기에는 **친구에만 있는 것**만 둔다.
class FriendArt {
  const FriendArt._();

  static const String _list = 'assets/images/scene_friend/friend_list';
  static const String _recv = 'assets/images/scene_friend/application_received';

  // ── 화면 ─────────────────────────────────────────────────
  static const String background = '$_list/back_friends.png';

  static const String title = '$_list/title_friends.png';
  static const Size titleSize = Size(147, 71);

  /// 탭 — 자리·크기는 대화방과 같다(`TalkArt.tab*`).
  static const String tabFriendsOn = '$_list/button_friends_color.png';
  static const String tabFriendsOff = '$_list/button_friends_normal.png';

  /// `[받은 신청]` 탭은 **대화방 그림을 그대로 가리킨다.** 전달본 `Scene_Friend`에도 같은 이름으로
  /// 있지만 **바이트까지 같다**(md5 확인, 2026-09-19) — 복사본을 두면 일본어판을 받을 때 두 곳에
  /// 넣어야 하고 한쪽만 바뀌면 두 탭이 어긋난다. 그래서 들이지 않았다.
  static const String tabReceiveOn = TalkArt.tabReceiveOn;
  static const String tabReceiveOff = TalkArt.tabReceiveOff;

  // ── [친구 목록] — 원형 3열 ──────────────────────────────────
  /// 원형 테두리(선만 있고 안이 비었다). 그 아래에 프로필 사진을 **원으로** 깔고 얹는다.
  static const String circleFrame = '$_list/frame_friends.png';
  static const Size circleSize = Size(315, 315);

  /// 원이 그림 가장자리에서 **4px 안쪽**에서 시작하고 선은 **2px**다(알파 실측).
  /// 사진은 여백 + 선 두께의 70%만큼 안으로 넣는다 — 선 아래에 살짝 물려 틈이 안 생기고
  /// 선 밖으로는 구조적으로 못 나간다(함정 #51·#52).
  static const double circleMargin = 4;
  static const double circleLine = 2;
  static const double circlePhotoInset = circleMargin + circleLine * 0.7;

  /// 칸의 왼쪽 선 — 시안 `23` · `385` · `743`. 첫 줄 윗선 `536`, 다음 줄 `1106`(간격 570).
  static const double gridLeft = 23;
  static const double gridTop = 536;
  static const double rowPitch = 1106 - 536;

  /// 세 칸 사이 간격 — 좌우 대칭으로 `(1080 − 23·2 − 315·3) / 2`.
  static const double gridGapX = (1080 - 23 * 2 - 315 * 3) / 2;

  /// 탭 아래(356 + 98) → 첫 줄(536).
  static const double tabsToGrid = 536 - (356 + 98);

  // 칸 안 요소 — 칸 왼쪽 위 기준(시안 좌표 − 칸 원점 `23, 536`).

  /// 고정 핀(작은 것) — 시안 `280, 517`. 원 오른쪽 위로 **튀어나온다**.
  static const String pinSmall = '$_list/icon_pinmark.png';
  static const Size pinSmallSize = Size(56, 55);
  static const Offset pinSmallAt = Offset(280 - 23, 517 - 536);

  /// 국기(원형) — 시안 `148, 807`. 원 아래 가장자리에 걸친다.
  static const String flagKr = '$_list/icon_mflag_kor.png';
  static const String flagJp = '$_list/icon_mflag_jap.png';
  static const Size flagSize = Size(60, 60);
  static const Offset flagAt = Offset(148 - 23, 807 - 536);

  static String? flagOf(String? country) => switch (country) {
    'KR' => flagKr,
    'JP' => flagJp,
    _ => null,
  };

  /// 이름·나이 / 도시 / 접속 세 줄의 윗선(예시 그림에서 잰 값 — 좌표 표기가 없다).
  static const double nameTop = 884 - 536;
  static const double cityTop = 940 - 536;
  static const double presenceTop = 997 - 536;

  /// `● ON` — 초록 점과 `ON`이 한 장에 구워져 있다(영어라 두 언어 모두 그대로 쓴다 — 14 §1).
  static const String online = '$_list/icon_monline.png';
  static const Size onlineSize = Size(85, 25);

  // ── [친구 포스트 정보] 팝업 ────────────────────────────────
  /// 고정 핀(큰 것) — 시안 `76, 174`. 대화방 팝업의 뒤로가기 자리다(이 팝업에는 화살표가 없다).
  static const String pinLarge = '$_list/icon_pinmark_l.png';
  static const Size pinLargeSize = Size(120, 119);

  /// 흰 패널 왼쪽 — 연필(소개). 시안 `75, 1515` — 다른 팝업의 편지(`1526`)보다 11px 위다.
  static const String bio = '$_list/button_bio.png';
  static const Size bioSize = Size(79, 79);
  static const double bioLeft = 75 - 24;
  static const double bioTop = 1515 - 1487;

  /// `[친구 관리]` — 시안 `715, 1526`.
  static const String manage = '$_list/button_management.png';
  static const Size manageSize = Size(294, 77);
  static const double manageLeft = 715 - 24;

  /// 패널 아래 줄 — 하트(관심사 표시) + 관심사 칩 셋. 시안 `75, 2002` · `220` · `483` · (`746`).
  static const String interestsIcon = '$_list/button_Interests.png';
  static const Size interestsIconSize = Size(83, 67);
  static const double interestsIconLeft = 75 - 24;
  static const List<double> chipLefts = [220 - 24, 483 - 24, 746 - 24];
  static const double footerHeight = 89; // 관심사 칩(204×89) 높이

  /// 줄 아래 끝(2002 + 89 = 2091) → 패널 마개 아래 끝(2099).
  static const double footerBottom = 2099 - (2002 + 89);

  /// `[나가기]` — 시안 `260, 2168`. 오른쪽 `[💬 대화하기]`는 대화방 그림(`TalkArt.accept`)이다.
  static const String exit = '$_list/button_exit.png';

  // ── [친구 요청 상세] 팝업 ──────────────────────────────────
  /// `[✓ 요청 수락]` — 시안 `636, 2168`. 이것만 새로 왔고 나머지는 대화방 팝업 그림이다.
  static const String acceptFriend = '$_recv/button_acceptfriend.png';
}
