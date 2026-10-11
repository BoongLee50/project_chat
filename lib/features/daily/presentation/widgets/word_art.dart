import 'package:flutter/widgets.dart';

/// 달빛 한마디 그림·좌표(`Plan_Chat/UI/Scene_Word`, 2026-10-11 전달). 숫자는 전부 **1080 캔버스 픽셀**이다
/// (`Example/*좌표.png`에 적힌 값 그대로).
///
/// 전달 폴더 세 개 → 화면 셋:
/// - `Title`          → [타이틀] `DailyIntroScreen`
/// - `Reply Register` → [내 한마디 등록] 시트(타이틀 위로 올라온다)
/// - `Reply List`     → [답글 목록] `DailyListScreen`
///
/// 🇯🇵 글자가 구워진 그림의 일본어판은 같은 이름으로 `ja/`에 있다(`DesignCanvas.localizedAssets`).
/// ⚠️ **일본어판이 안 온 것**: `button_join`(참여하기) · `button_recent_*`(최신) · `button_popul_*`(인기) —
/// 일본어 화면에도 한국어 그림이 나간다(docs/08 §0).
class WordArt {
  const WordArt._();

  static const String _title = 'assets/images/scene_word/title';
  static const String _register = 'assets/images/scene_word/reply_register';
  static const String _list = 'assets/images/scene_word/reply_list';

  // ── [타이틀] ─────────────────────────────────────────────

  /// 배경 전체(1080×2640) — 「달빛 한마디」 머리·18시 안내·빈 질문 카드가 **구워져 있다**.
  /// ⚠️ 전달 파일 이름이 `back_friends_kr/jp`다(친구 화면 것이 아니다 — 이름만 그렇게 왔다).
  static const String titleBack = '$_title/back_friends.png';

  /// `<` 나가기 — 가든(메인)으로 돌아간다(기획 9-1).
  static const String exitMoon = '$_title/button_exit_moon.png';
  static const Size exitMoonSize = Size(68, 116);
  static const Offset exitMoonAt = Offset(55, 103);

  /// 구워진 질문 카드의 점선 칸. 카드가 **기울어져 있어** 질문 글자도 같이 돌린다.
  /// 배경을 실측했다: 점선 칸 가운데 ≈ (562, 1426), 윗변·아랫변 기울기 ≈ -10°.
  static const Offset questionCenter = Offset(562, 1426);
  static const Size questionBox = Size(600, 230);
  static const double questionAngle = -0.17; // 라디안(≈ -10°)

  static const String clock = '$_title/icon_clock.png';
  static const Size clockSize = Size(52, 52);

  /// 시계 줄 윗변(`311, 2180`) — 가로는 [joinAt] 기준 가운데에 둔다.
  static const double clockTop = 2180;

  static const String join = '$_title/button_join.png';
  static const Size joinSize = Size(834, 167);
  static const Offset joinAt = Offset(124, 2285);

  // ── [내 한마디 등록] 시트 ─────────────────────────────────

  /// 시트 바탕(1036×1976) — 초승달·「오늘의 질문」·🔒 잠금 안내·`사진 추가(선택 사항)`가 **구워져 있다**.
  static const String sheetBack = '$_register/back_word.png';
  static const Size sheetSize = Size(1036, 1976);

  /// 시트 왼쪽 위(캔버스 기준). 아래 좌표는 모두 **시트 기준**으로 바꿔 둔다.
  static const Offset sheetAt = Offset(22, 578);

  static const String close = '$_register/button_wordclose.png';
  static const Size closeSize = Size(124, 124);
  static const Offset closeAt = Offset(899 - 22, 603 - 578);

  /// 질문 글(`179, 869`) — 두 줄 가운데 정렬.
  static const double sheetQuestionTop = 869 - 578;

  static const String replyFrame = '$_register/frame_reply.png';
  static const Size replyFrameSize = Size(904, 483);
  static const Offset replyFrameAt = Offset(85 - 22, 1252 - 578);

  /// 입력 글 시작(`139, 1311`) — 틀 안쪽 여백.
  static const Offset replyTextInset = Offset(139 - 85, 1311 - 1252);

  static const String addPhoto = '$_register/frame_addphoto.png';
  static const Size addPhotoSize = Size(486, 430);
  static const Offset addPhotoAt = Offset(85 - 22, 1770 - 578);

  /// 구워진 `📷 사진 추가 (선택 사항)` 글자 자리 — 여기를 눌러도 사진을 고른다.
  static const Rect addPhotoLabel = Rect.fromLTWH(
    620 - 22,
    1880 - 578,
    330,
    260,
  );

  static const String deletePhoto = '$_register/icon_deletephoto.png';
  static const Size deletePhotoSize = Size(68, 68);
  static const Offset deletePhotoAt = Offset(482 - 22, 1786 - 578);

  static const String register = '$_register/button_register.png';
  static const Size registerSize = Size(834, 167);
  static const Offset registerAt = Offset(122 - 22, 2285 - 578);

  // ── [답글 목록] ──────────────────────────────────────────

  /// 바탕(1080×2640, 미색 한 장).
  static const String listBack = '$_list/back_word.png';

  /// 「오늘의 질문」 머리(1032×224) — 질문 글은 `43, 201`부터 흰 글자로 얹는다.
  static const String questionFrame = '$_list/frame_question.png';
  static const Size questionFrameSize = Size(1032, 224);
  static const double questionFrameTop = 102;
  static const Offset questionTextInset = Offset(43 - 23, 201 - 102);

  static const String recentOn = '$_list/button_recent_color.png';
  static const String recentOff = '$_list/button_recent_normal.png';
  static const Size recentSize = Size(287, 96);
  static const String popularOn = '$_list/button_popul_color.png';
  static const String popularOff = '$_list/button_popul_normal.png';
  static const Size popularSize = Size(288, 97);
  static const String myWord = '$_list/button_myword.png';
  static const Size myWordSize = Size(333, 97);

  /// 필터 줄 윗변·칸 왼쪽(`23 / 331 / 720, 356`).
  static const double filterTop = 356;
  static const double recentLeft = 23;
  static const double popularLeft = 331;
  static const double myWordLeft = 720;

  /// 목록 칸(셀이 쌓이는 곳) 윗변·아랫변(`23, 478` ~ `23, 2416`).
  static const double listTop = 478;
  static const double listBottom = 2416;

  /// 셀 틀(1045×647). 글 길이·사진 유무로 높이가 달라 **9조각으로 늘린다**(모서리 둥근 흰 칸이라 늘려도 같다).
  static const String cellFrame = '$_list/frame_replylist.png';
  static const Size cellFrameSize = Size(1045, 647);
  static const Rect cellFrameSlice = Rect.fromLTWH(60, 60, 925, 527);

  /// 셀 사이(1125 → 1129 실측, 틀 그림자를 빼면 거의 붙어 있다).
  static const double cellGap = 4;

  /// 셀 안 좌표(셀 왼쪽 위 `23, 478` 기준).
  static const String avatarFrame = '$_list/frame_userprofile.png';
  static const Size avatarSize = Size(161, 161);
  static const Offset avatarAt = Offset(55 - 23, 502 - 478);
  static const double textLeft = 252 - 23;
  static const double nameTop = 518 - 478;
  static const double cellRight = 1053 - 23;

  static const String detail = '$_list/icon_detail.png';
  static const Size detailSize = Size(32, 54);
  static const double detailLeft = 992 - 23;

  static const String flagKr = '$_list/icon_mmflag_kor.png';
  static const String flagJp = '$_list/icon_mmflag_jap.png';
  static const Size flagSize = Size(41, 41);
  static const String online = '$_list/icon_mmonline.png';
  static const Size onlineSize = Size(78, 25);

  /// 본문 사진 틀(312×286) — `252, 741`.
  static const String photoFrame = '$_list/frame_upload.png';
  static const Size photoSize = Size(312, 286);

  static const String heart = '$_list/icon_heart.png';
  static const Size heartSize = Size(50, 47);
  static const String comment = '$_list/icon_comment.png';
  static const Size commentSize = Size(46, 45);

  /// 좋아요 `257` · 댓글 `457` — 둘 사이 간격.
  static const double countGap = 457 - 257;

  static const String exit = '$_list/button_roomexit.png';
  static const Size exitSize = Size(148, 147);
  static const double exitLeft = 55;

  /// 나가기 아래 여백(2640 - 2435 - 147).
  static const double exitBottom = 2640 - 2435 - 147;

  /// 글자색 — 시안 실측(이름·본문은 짙은 남색 · 시간은 회색 · 남은 시간 숫자는 금색 `254,182,68`).
  static const Color ink = Color(0xFF14213D);
  static const Color muted = Color(0xFFA7A7AE);
  static const Color gold = Color(0xFFFEB644);
}
