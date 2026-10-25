import 'package:flutter/material.dart';

/// 채팅창 리소스(`Plan_Chat/UI/Scene_Chat`, 2026-10-25 첫 전달본). 경로와 **시안 원본 규격**만 모은다.
///
/// 좌표는 `Example/채팅창 좌표값.png`의 **1080 캔버스 픽셀값**, 글자 크기·색·간격은
/// `Example/채팅창 참고 화면.png`을 실측했다(좌표값 그림과 참고 화면은 세로로 15px쯤 어긋나 있다 —
/// 좌표가 적힌 자리는 좌표값을, 안 적힌 자리는 참고 화면을 따랐다).
///
/// 📌 다섯 장은 달빛 한마디(`scene_word/reply_detail`)에 **바이트까지 같은 그림**이 이미 있다
/// (`button_infotrans` · `button_message_*` · `icon_flag_*`). 그래도 이 폴더에 따로 들였다 —
/// 전달 폴더가 다르면 다음 전달본에서 한쪽만 바뀔 수 있다.
class ChatArt {
  const ChatArt._();

  static const String _dir = 'assets/images/scene_chat';

  /// 화면 바탕(1080×2640, 단색 `#FFFEFB`). 그림으로 깔아 두면 바탕이 바뀌어 와도 코드는 그대로다.
  static const String background = '$_dir/back_chat.png';
  static const Color paper = Color(0xFFFFFEFB);

  // ── 머리(상단 바) ─────────────────────────────────────────────

  /// 시안 머리는 상태바 자리(약 100)를 포함해 그려져 있다. 실제로는 상태바 아래부터 쌓는다.
  static const double statusBarInDesign = 100;

  /// 머리 한 줄의 가운데 — 뒤로·사진·이름·[⋯]가 모두 이 선에 맞춰져 있다(`190`).
  static const double headerCenter = 190;

  /// 머리 아랫변 — 여기서 그림자 띠(`frame_chat_titledividing`)가 시작한다(`0, 285`).
  static const double headerBottom = 285;

  static const String back = '$_dir/button_previewback_chat.png';
  static const Size backSize = Size(32, 54);
  static const double backLeft = 52;

  static const String profileRing = '$_dir/frame_chat_profile.png';
  static const double profileSize = 124;
  static const double profileLeft = 155;

  /// 이름(`319, 164`). 이름은 굵게, 나이는 보통 굵기 — 같은 크기.
  static const double nameLeft = 319;
  static const double nameFont = 58;
  static const Color nameInk = Color(0xFF141413);

  /// 국기는 나이 글자 끝에서 `32` 띄운다(실측 506 → 538).
  static const String flagKr = '$_dir/icon_flag_kor.png';
  static const String flagJp = '$_dir/icon_flag_jap.png';
  static const double flagSize = 70;
  static const double flagGap = 32;

  static String? flagOf(String? country) => switch (country) {
    'KR' => flagKr,
    'JP' => flagJp,
    _ => null,
  };

  /// [⋯] 채팅 관리 패널(`967, 184`). 그림이 70×12로 얇아서 누르는 자리는 따로 넓힌다.
  static const String viewMore = '$_dir/button_chat_viewmore.png';
  static const Size viewMoreSize = Size(70, 12);
  static const double viewMoreLeft = 967;

  /// 머리 아래 그림자 띠(1080×27). 위가 진하고 아래로 옅어진다 — 목록이 그 밑으로 지나간다.
  static const String headerShadow = '$_dir/frame_chat_titledividing.png';
  static const double headerShadowHeight = 27;

  // ── 안내 줄: `작은 배려, 아름다운 대화` · [번역 | …] ─────────────────

  /// 줄 윗변(`757, 312`의 y) · 높이는 [번역] 그림 높이(83).
  static const double noticeTop = 312;

  /// 🚧 **문구 그림이 안 왔다** — 고정 문구라 그림이 맡을 자리인데(14 §3) 전달본에 없어 폰트로 쓴다.
  static const double sloganLeft = 52;
  static const double sloganFont = 42;
  static const Color sloganInk = Color(0xFFAE804D);

  static const String infoTrans = '$_dir/button_infotrans.png';
  static const Size infoTransSize = Size(292, 83);
  static const double infoTransLeft = 757;

  /// `번역 |` 오른쪽 빈칸(그림 안 x 190~282) — 남은 일수·무료 횟수 글자 자리.
  /// 달빛 한마디(`WordArt.infoTransLabel`)와 같은 그림이라 같은 값이다.
  static const Rect infoTransLabel = Rect.fromLTWH(190, 0, 92, 83);
  static const Color infoTransInk = Color(0xFFB0793F);

  // ── 메시지 ───────────────────────────────────────────────────

  /// 첫 줄 윗변(상대 얼굴 `25, 429`).
  static const double listTop = 429;
  static const double sidePad = 25;

  /// 상대 얼굴 틀(116). 말풍선은 얼굴보다 `23` 아래에서 시작한다(`155, 452`).
  static const String avatarRing = '$_dir/frame_chat_commentprofile_.png';
  static const double avatarSize = 116;
  static const double avatarToBubble = 155 - 25 - avatarSize;
  static const double bubbleDrop = 452 - 429;

  /// 내 말풍선 오른쪽 끝(꼬리 포함, `1039, 694`).
  static const double myBubbleRight = 1039;

  /// 내 줄 왼쪽에 더 비워 두는 폭 — 시간(약 132) 옆으로 남는 자리. 내 말풍선은 최대 700쯤이 된다.
  static const double myReserve = 150;

  /// 말풍선과 말풍선 사이(실측 약 58). 얼굴이 23 위로 솟으므로 줄 사이는 그만큼 뺀 값이다.
  static const double rowGap = 58 - bubbleDrop;

  /// 말풍선 그림(578×107). 글 길이에 맞춰 **9조각으로 늘린다** — 모서리·꼬리는 그대로,
  /// 가운데만 늘어난다. 가운데 조각은 그림 속 **깨끗한 구간**에서 골랐다
  /// (내 말풍선은 왼쪽 x 45·75에 옅은 세로줄이 있어 그 바깥에서 자른다).
  static const String counterBubble = '$_dir/frame_counterchatbox.png';
  static const String myBubble = '$_dir/frame_mychatbox.png';
  static const Size bubbleSize = Size(578, 107);
  static const Rect counterSlice = Rect.fromLTRB(60, 36, 530, 72);
  static const Rect mySlice = Rect.fromLTRB(100, 34, 520, 62);

  /// 말풍선 안 글자 자리 — 꼬리가 있는 쪽이 넓다.
  static const EdgeInsets counterPad = EdgeInsets.fromLTRB(47, 28, 40, 30);
  static const EdgeInsets myPad = EdgeInsets.fromLTRB(40, 28, 53, 30);

  /// 본문 글자 — 40, 줄 간격 61(실측).
  static const double messageFont = 40;
  static const double messageLineHeight = 61 / 40;
  static const Color messageInk = Color(0xFF14181F);

  /// 시간(`오후 8:12`) — 말풍선에서 32 떨어져, 아랫변보다 23 위에 놓인다.
  static const double timeFont = 32;
  static const double timeGap = 32;
  static const double timeLift = 23;
  static const Color timeInk = Color(0xFFA4806B);

  // ── 음성 메시지 ─────────────────────────────────────────────

  /// 재생·멈춤(108). 말풍선 안에서는 `42, 30`, 입력칸 안에서는 오른쪽 끝.
  static const String play = '$_dir/button_playback.png';
  static const String pause = '$_dir/button_playstop.png';
  static const double playSize = 108;

  /// 음성 말풍선(`155, 1427` — 665×168). 재생 버튼이 `197, 1460`, 파형이 `321`에서 시작한다.
  static const double voiceBubbleWidth = 665;
  static const EdgeInsets voicePad = EdgeInsets.fromLTRB(42, 30, 33, 30);
  static const double playToWave = 321 - 197 - playSize;
  static const double waveHeight = 66;
  static const double durationFont = 40;
  static const Color waveInk = Color(0xFF4A5162);

  // ── 입력줄(`2373`) ─────────────────────────────────────────

  /// [GIF] `25` · 메시지 칸 `164`(751×122) · [음성]/[보내기] `935`.
  static const String gif = '$_dir/button_chat_gif.png';
  static const String record = '$_dir/button_chat_recording.png';
  static const String delete = '$_dir/button_chat_delete.png';
  static const String sendOn = '$_dir/button_message_color.png';
  static const String sendOff = '$_dir/button_message_normal.png';
  static const double roundButton = 120;

  static const String inputFrame = '$_dir/frame_chatmessage.png';
  static const Size inputFrameSize = Size(751, 122);
  static const double inputLeft = 25;
  static const double inputGap = 19;

  /// 힌트 글자는 칸 왼쪽에서 48(`212, 2416`).
  static const double inputTextLeft = 48;
  static const double inputFont = 40;
  static const Color hintInk = Color(0xFF646A78);
}
