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
  /// 실측대로 돌리니 글자가 편지보다 덜 기울어 보여 **오른쪽을 더 올렸다**(-10° → -12° → **-11°**, 2026-10-11 사용자 지시).
  static const Offset questionCenter = Offset(562, 1426);
  static const Size questionBox = Size(600, 230);
  static const double questionAngle = -0.192; // 라디안(≈ -11°)

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

  /// 목록 셀 [원문보기](182×53, 2026-10-11 두 번째 전달). 전엔 대화방 `button_view_trans`를 빌려 썼다.
  static const String viewOriginal = '$_list/button_view_trans_m.png';
  static const Size viewOriginalSize = Size(182, 53);

  // ── [답글 상세] (`Reply Detail`, 2026-10-11 두 번째 전달) ─────────────

  static const String _detail = 'assets/images/scene_word/reply_detail';

  /// 머리(고정) — `<` · 얼굴 · 이름 나이 · 국기. 아래 `frame_titledividing`부터 스크롤이다.
  static const String detailBack = '$_detail/button_previewback.png';
  static const Size detailBackSize = Size(60, 101);
  static const Offset detailBackAt = Offset(43, 138);
  static const String detailAvatar = '$_detail/frame_userprofile.png';
  static const Size detailAvatarSize = Size(161, 161);
  static const Offset detailAvatarAt = Offset(177, 115);
  static const double detailNameLeft = 393;
  static const String detailFlagKr = '$_detail/icon_flag_kor.png';
  static const String detailFlagJp = '$_detail/icon_flag_jap.png';
  static const Size detailFlagSize = Size(70, 70);
  static const double detailHeaderHeight = 284;
  static const String titleDivider = '$_detail/frame_titledividing.png';
  static const Size titleDividerSize = Size(1080, 27);

  /// 본문(`59, 312`) · 큰 사진 틀(`25, 484`, 1045×1111).
  static const double detailTextLeft = 59;
  static const String detailPhotoFrame = '$_detail/frame_commentphoto.png';
  static const Size detailPhotoSize = Size(1045, 1111);
  static const double detailPhotoLeft = 25;

  /// 좋아요·댓글 줄(`61 / 330, 1605`) · [번역](`758, 1595`, 292×83).
  static const String detailHeart = '$_detail/button_heart.png';
  static const Size detailHeartSize = Size(72, 67);
  static const String detailComment = '$_detail/icon_comment.png';
  static const Size detailCommentSize = Size(70, 67);
  static const double detailHeartLeft = 61;
  static const double detailCommentLeft = 330;
  static const String infoTrans = '$_detail/button_infotrans.png';
  static const Size infoTransSize = Size(292, 83);
  static const double infoTransLeft = 758;

  /// `번역 |` 오른쪽 빈칸(그림 안 x 190~282) — 남은 일수·무료 횟수 글자 자리.
  static const Rect infoTransLabel = Rect.fromLTWH(190, 0, 92, 83);
  static const Color infoTransInk = Color(0xFFB0793F);

  static const String listDivider = '$_detail/frame_listdividing.png';
  static const Size listDividerSize = Size(1031, 4);

  /// 댓글 줄. 얼굴은 깊이마다 오른쪽으로(1단계 `50` · 2단계 `170` · 3단계 `251`),
  /// 답글 앞에는 `ㄴ`(`icon_link` — 2단계 `128` · 3단계 `211`).
  static const String commentAvatar = '$_detail/frame_commentprofile.png';
  static const double commentAvatarSize = 124;
  static const List<double> commentAvatarLeft = [50, 170, 251];
  static const String link = '$_detail/icon_link.png';
  static const Size linkSize = Size(29, 59);
  static const List<double> linkLeft = [0, 128, 211];
  static const String commentFlagKr = '$_detail/icon_mmflag_kor.png';
  static const String commentFlagJp = '$_detail/icon_mmflag_jap.png';

  /// 댓글 사진(`326, 2064` 실측 ≈ 185×169).
  static const Size commentPhotoSize = Size(185, 169);

  /// 아래 입력줄(고정, `2373`) — [사진] `24` · 메시지 칸 `160`(751×122) · 보내기 `932`(119×118).
  static const String messageFrame = '$_detail/frame_message.png';
  static const Size messageFrameSize = Size(751, 122);
  static const String sendOn = '$_detail/button_message_color.png';
  static const String sendOff = '$_detail/button_message_normal.png';
  static const Size sendSize = Size(119, 118);

  /// 🚧 **[사진] 버튼 그림은 안 왔다** — 노란 원(보내기와 같은 색)에 아이콘을 얹어 자리만 채운다.
  static const double photoButtonSize = 120;
  static const Color yellow = Color(0xFFFDC302);

  /// 배경 미색(시안 실측 253,243,230).
  static const Color paper = Color(0xFFFDF3E6);

  /// 글자색 — 시안 실측(이름·본문은 짙은 남색 · 시간은 회색 · 남은 시간 숫자는 금색 `254,182,68`).
  static const Color ink = Color(0xFF14213D);
  static const Color muted = Color(0xFFA7A7AE);
  static const Color gold = Color(0xFFFEB644);
}
