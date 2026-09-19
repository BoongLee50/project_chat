import 'package:flutter/material.dart';

/// 대화방 화면 리소스(`Plan_Chat/UI/Scene_Talk`, 2026-09-19 전달본). 경로와 **시안 원본 규격**만 모은다.
///
/// 좌표는 `대화방_대화목록창 좌표.png` · `대화방_받은신청_팝업창 좌표.png`의 **1080 캔버스 픽셀값**이다.
///
/// 🚨 **`icon_next`(오른쪽 화살표)는 일부러 들이지 않았다.** 예시 그림에는 셀 안에 `>`가 있지만
/// 기획사항(2026-09-19)이 *"뒤로가기 말고는 대화방에는 화살표가 없음!"* 이라고 못 박았다.
/// 신뢰 순서가 **기획사항 > 기획서 > 이미지**라서 그림 쪽이 진다.
class TalkArt {
  const TalkArt._();

  static const String _list = 'assets/images/scene_talk/talk_list';
  static const String _recv = 'assets/images/scene_talk/application_received';

  // ── 대화 목록 · 받은 신청 (한 화면, 탭만 바뀐다) ─────────────────

  /// 화면 배경. 위쪽에 밤 방 풍경(책·폰·고양이)이 있고 아래는 어둠으로 이어진다.
  static const String background = '$_list/back_room.png';

  static const String title = '$_list/title_room.png';
  static const Size titleSize = Size(221, 72);

  /// 탭 버튼 — 고른 쪽은 `_color`(노란 테두리), 아닌 쪽은 `_normal`(흰 테두리).
  static const String tabListOn = '$_list/button_list_color.png';
  static const String tabListOff = '$_list/button_list_normal.png';
  static const String tabReceiveOn = '$_list/button_receive_color.png';
  static const String tabReceiveOff = '$_list/button_receive_normal.png';
  static const Size tabSize = Size(484, 98);
  static const double tabListLeft = 23;
  static const double tabReceiveLeft = 571;

  /// 탭 안의 빨간 점(숫자가 얹힌다 — 99가 최대). 탭 왼쪽 위 기준 자리.
  /// 시안 `430, 377` / `977, 377`에서 탭 원점(`23, 356` / `571, 356`)을 뺐다.
  static const String redDot = '$_list/icon_unconfirm.png';
  static const Size redDotSize = Size(55, 56);
  static const Offset redDotInTab = Offset(407, 21);

  /// 셀 한 칸. **두 열**로 깔린다(시안 `24, 499` · 다음 줄 `24, 1047`).
  ///
  /// 그림은 **외곽선 + 아래쪽 어둠(그러데이션)** 이고 가운데가 비어 있다 — 그 아래에
  /// 상대 프로필 사진을 깔고 이 그림을 위에 얹는다. 실측(알파):
  /// 선 두께 3px, 바깥 곡률 약 34px, 어둠은 높이 55%쯤에서 시작해 90%에서 거의 불투명.
  static const String cellFrame = '$_list/frame_list.png';
  static const Size cellSize = Size(504, 522);
  static const double cellLeft = 24;

  /// 두 열 사이 간격 — 좌우 대칭이 되게 `1080 − 24 − 504·2 − 24`.
  static const double cellGapX = 24;

  /// 줄 간격 — 시안 다음 줄 `1047` − 첫 줄 `499` − 셀 높이 `522`.
  static const double cellGapY = 1047 - 499 - 522;

  /// 사진을 프레임 안쪽에 맞춰 자를 때 쓰는 값(실측).
  static const double cellLine = 3;
  static const double cellRadius = 34;

  // 셀 안 요소 — 셀 왼쪽 위 기준(시안 좌표 − 셀 원점 `24, 499`).
  static const String online = '$_list/icon_online.png';
  static const Size onlineSize = Size(144, 46);
  static const Offset onlineAt = Offset(22, 23); // 46, 522

  /// 미확인 표시 `N`(기획서 [미확인 표시] — "마지막 메시지를 아직 확인하지 않았을 경우").
  static const String newMark = '$_list/icon_newmark.png';
  static const Size newMarkSize = Size(54, 55);
  static const Offset newMarkAt = Offset(426, 24); // 450, 523

  /// 이름·나이 줄과 메시지 줄의 윗선.
  static const double nameTop = 832 - 499;
  static const double messageTop = 907 - 499;
  static const double textLeft = 46 - 24;

  /// 시간(`5분 전`)의 오른쪽 여백 — 예시에서 셀 오른쪽 끝과 글자 끝의 거리.
  static const double timeRight = 28;

  /// 국기(원형). 이름·나이 옆, 그리고 받은 신청 팝업에도 쓴다.
  static const String flagKr = '$_list/icon_sflag_kor.png';
  static const String flagJp = '$_list/icon_sflag_jap.png';
  static const Size flagSize = Size(47, 47);

  static String? flagOf(String? country) => switch (country) {
    'KR' => flagKr,
    'JP' => flagJp,
    _ => null,
  };

  // ── 받은 신청 팝업(= 기획서의 [포스트 정보]) ────────────────────

  /// 사진 테두리. **위 모서리만 둥글고 아래가 열려 있다** — 바로 밑에 흰 패널이 붙는다.
  /// 실측: 선 6px, 곡률 약 26px, 안은 전부 투명.
  static const String popupTop = '$_recv/frame_popup_top.png';
  static const Size popupTopSize = Size(1032, 1381);
  static const double popupLeft = 24;
  static const double popupTopY = 106;
  static const double popupLine = 6;
  static const double popupRadius = 26;

  /// 흰 패널의 **아래 마개**(아래 모서리가 둥글다). 패널 가운데는 흰색으로 채우고
  /// 글이 길어지면 **아래로 늘어난다**(기획사항 — "문구가 길어질 경우 아래로 영역이 늘어남").
  static const String popupBottom = '$_recv/frame_popup_bottom.png';
  static const Size popupBottomSize = Size(1032, 166);

  /// 흰 패널의 최소 높이(마개 제외) — 시안에서 사진 아래 `1487` ~ 마개 위 `1933`.
  static const double panelMinBody = 1933 - 1487;

  static const String back = '$_recv/button_back.png';
  static const Size backSize = Size(52, 98);
  static const Offset backAt = Offset(76 - 24, 174 - 106); // 팝업 기준

  /// `1/9` 숫자 — 폰트(값이 변한다). 시안 `918, 174`.
  static const Offset pageAt = Offset(918 - 24, 174 - 106);

  // 흰 패널 첫 줄 — 패널 윗선(`1487`) 기준.
  static const String message = '$_recv/icon_message.png';
  static const Size messageSize = Size(89, 64);
  static const double messageLeft = 72 - 24;

  static const String viewOriginal = '$_recv/button_view_trans.png';
  static const Size viewOriginalSize = Size(209, 73);
  static const double viewOriginalLeft = 211 - 24;

  static const String profile = '$_recv/button_profile.png';
  static const Size profileSize = Size(256, 78);
  static const double profileLeft = 770 - 24;

  static const double panelRowTop = 1526 - 1487;

  /// 본문 글의 왼쪽 선 — 예시 그림에서 잰 값(좌표 표기가 없다).
  static const double panelTextLeft = 108 - 24;

  // 아래 두 버튼 — 패널 아래 `2099`에서 `2168`까지 띄운다.
  static const String refuse = '$_recv/button_refusal.png';
  static const String accept = '$_recv/button_accept.png';
  static const Size decideSize = Size(177, 176);
  static const double refuseLeft = 260;
  static const double acceptLeft = 636;
  static const double panelToButtons = 2168 - 2099;
}
