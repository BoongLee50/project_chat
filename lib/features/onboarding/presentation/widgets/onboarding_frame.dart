import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';

/// 온보딩(가입 정보 입력) 그림 — `그래픽 소스\로그인 화면\1~7`(2026-11-21).
///
/// 공용 조각(머리 배경 · 흰 판 · 진행 표시 · 앞뒤 버튼)은 STEP 1 폴더로 왔다 → `scene_login/step1/`.
abstract final class OnboardingArt {
  static const _s1 = 'assets/images/scene_login/step1';
  static const _s2 = 'assets/images/scene_login/step2';
  static const _s3 = 'assets/images/scene_login/step3';
  static const _s4 = 'assets/images/scene_login/step4';

  /// 머리 배경(보라 그라데이션 + 필기체 `Profile`, 1080×728). `프로필`·설명 두 줄은 **글자**다.
  static const headerBack = '$_s1/back_porfile_top.png';

  /// 흰 판의 둥근 윗변(1083×365) — 시안 y≈630에서 시작한다.
  static const cardTop = '$_s1/back_porfile_bottom.png';

  static const back = '$_s1/button_profile_back.png'; // 172×171
  static const next = '$_s1/button_profile_next.png'; // 170×171

  static const markComplete = '$_s1/icon_porfile_completemark.png'; // 58
  static const markProgress = '$_s1/icon_porfile_progressmark.png'; // 50
  static const markPending = '$_s1/icon_porfile_pendingmark.png'; // 43
  static const barFill = '$_s1/icon_porfile_fillbar.png'; // 40×4
  static const barUnfill = '$_s1/icon_porfile_unfillbar.png';

  /// `STEP n` 배지(239×104). 지금은 1~3만 왔다 — 없는 단계는 `null`이고, 판이 같은 자리·크기의
  /// 보라 알약을 코드로 그린다(🚧 자리 표시 — 그림이 오면 여기 한 줄).
  static String? stepBadge(int step) => switch (step) {
    1 => '$_s1/icon_porfile_step1.png',
    2 => '$_s2/icon_porfile_step2.png',
    3 => '$_s3/icon_porfile_step3.png',
    _ => null,
  };

  // STEP 1 성별
  static const illustGender =
      '$_s1/back_porfile_gender.png'; // 513×421 @ 491,144
  static const maleOn = '$_s1/button_male_select.png'; // 415×458
  static const maleOff = '$_s1/button_male_unselect.png';
  static const femaleOn = '$_s1/button_female_select.png';
  static const femaleOff = '$_s1/button_female_unselect.png';

  // STEP 2 생년월일
  static const illustAge = '$_s2/back_porfile_age.png'; // 512×361 @ 513,198
  static const ageLabel = '$_s2/icon_porfile_age.png'; // 286×115 — `AGE`
  static const slash = '$_s2/icon_porfile_diagonal.png'; // 59×96
  static const underline = '$_s2/icon_porfile_underline.png'; // 66×14

  // STEP 3 거주 지역
  static const illustResidence =
      '$_s3/back_porfile_residence.png'; // 428×403 @ 557,150
  static const regionOn = '$_s3/button_profile_selectregion.png'; // 906×138
  static const regionOff = '$_s3/button_profile_unselectregion.png'; // 907×138

  // STEP 4 관심사
  static const illustInterest =
      '$_s4/back_porfile_interest.png'; // 479×440 @ 530,137
  static const chipOn = '$_s4/frame_interest_selected.png'; // 265×114
  static const chipOff = '$_s4/frame_interest_unselected.png'; // 265×114
  static const groupTrip = '$_s4/icon_interest_trip.png'; // 94×127
  static const groupArt = '$_s4/icon_interest_art.png'; // 123×98

  /// 진행 표시 일곱 칸의 가운데 — x = 292 + 83·i, y = 739(시안 실측).
  static const markCenterY = 739.0;
  static double markCenterX(int i) => 292 + 83.0 * i;

  /// 글자색(시안 실측). 회색 안내는 프로필과 같은 지정값(RGB 178,178,183)을 쓴다.
  static const ink = Color(0xFF2A2929);
  static const gray = Color(0xFFB2B2B7);
  static const purple = Color(0xFF8571C0);
}

/// 온보딩 한 단계의 판 — 시안 1080×2640을 **폭에 맞춰** 그대로 얹는다.
///
/// - 위(머리 ~ 안내 문구)는 시안 좌표 그대로, 아래 `<` `>` 버튼은 화면 아래에 붙인다 —
///   화면이 시안보다 짧으면 그 사이(빈 흰 공간)가 줄어든다. 고정 화면이라 **스크롤하지 않는다**(공통 규칙 §5).
/// - 🚫 시안 왼쪽 위의 `<` 화살표는 **그림 실수**다 — 없다(사용자 2026-11-21). 뒤로는 아래 `<` 버튼 하나.
/// - [onNext]가 이유(문구)를 돌려주면 넘어가지 않고 그 이유를 말한다(막힌 버튼은 이유를 말한다).
class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({
    super.key,
    required this.step,
    required this.illustration,
    required this.illustrationAt,
    required this.illustrationSize,
    required this.question,
    required this.questionTop,
    this.note,
    this.noteTop,
    this.content,
    this.body,
    required this.onBack,
    required this.onNext,
    this.keyboardLimit,
  }) : assert(note == null || noteTop != null);

  /// 1~7.
  final int step;

  final String illustration;
  final Offset illustrationAt;
  final Size illustrationSize;

  final String question;
  final double questionTop;

  /// 회색 안내 한 줄 — 없는 단계도 있다(STEP 4 관심사).
  final String? note;
  final double? noteTop;

  /// 이 단계만의 조각들 — 시안 좌표로 `Positioned`를 돌려준다(배율 s를 받는다).
  final List<Widget> Function(double s)? content;

  /// 질문 아래 ~ `<` `>` 버튼 사이를 채우는 칸 — 목록이 길어 화면을 넘는 단계(STEP 4 관심사 37종)가 쓴다.
  /// 판(머리·질문·버튼)은 그대로 두고 **이 칸 안만** 스크롤한다(고정 화면에서 늘어나는 칸이 흡수하는 원칙).
  final Widget? body;

  /// 뒤로. `null`이면 `<` 버튼이 없다 — STEP 1은 로그인 직후라 되돌아갈 곳이 없다(사용자 2026-11-21).
  final VoidCallback? onBack;

  /// 자판이 올라와도 **이 시안 y보다 위는 가리지 않는다**(생년월일 STEP 2 — `AGE` 윗선, 사용자 2026-11-21).
  ///
  /// 기기마다 자판 높이가 다르므로 고정 값으로 옮기지 않고, 지금 자판 높이(`viewInsets.bottom`)를 재서
  /// 자판 윗변이 이 선보다 위로 오는 만큼만 **위쪽 판을 통째로 밀어 올린다**(자판이 오르내리는 동안 따라 움직인다).
  /// 자판이 낮은 기기에서는 하나도 안 움직인다. `null`이면 자판을 신경 쓰지 않는다.
  final double? keyboardLimit;

  /// 다음으로 — 못 넘어가면 이유 문구를, 넘어가면 null을 돌려준다.
  final Future<String?> Function() onNext;

  /// 안내 문구 아래 여백까지가 위쪽 판의 높이다(안내가 없으면 질문 한 줄 아래까지).
  double get _topHeight => noteTop != null ? noteTop! + 100 : questionTop + 110;

  /// 자판 때문에 위쪽 판을 얼마나 올릴까(논리px) — [keyboardLimit] 설명대로. 테스트가 직접 부른다.
  @visibleForTesting
  static double keyboardLiftFor({
    required double? limit,
    required double scale,
    required double keyboard,
    required double keyboardTop,
  }) {
    if (limit == null || keyboard == 0) return 0;
    final over = limit * scale - keyboardTop;
    return over > 0 ? over : 0;
  }

  Future<void> _next(BuildContext context) async {
    final reason = await onNext();
    if (reason != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(reason)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final l10n = L10n.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // 시안의 버튼 아랫변(2295+171=2466) → 캔버스 아랫변(2640).
    final bottomGap = ((2640 - 2466) * s).clamp(
      safeBottom + 12,
      double.infinity,
    );
    // 자판 윗변(화면 좌표)이 지켜야 할 선보다 위로 올라온 만큼 위쪽 판을 올린다.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardTop = MediaQuery.sizeOf(context).height - keyboard;
    final lift = keyboardLiftFor(
      limit: keyboardLimit,
      scale: s,
      keyboard: keyboard,
      keyboardTop: keyboardTop,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        // 생년월일 자판이 올라와도 판을 줄이지 않는다(줄이면 위 그림이 넘친다). 자판은 위에 덮는다.
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Transform.translate(
                offset: Offset(0, -lift),
                child: SizedBox(
                  height: _topHeight * s,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const DesignPositioned(
                        left: 0,
                        top: 0,
                        child: ArtImage(
                          OnboardingArt.headerBack,
                          width: 1080,
                          height: 728,
                        ),
                      ),
                      DesignPositioned(
                        left: illustrationAt.dx,
                        top: illustrationAt.dy,
                        child: ArtImage(
                          illustration,
                          width: illustrationSize.width,
                          height: illustrationSize.height,
                        ),
                      ),
                      // `프로필`·설명은 그림 왼쪽(81 ~ 그림 시작) 폭 안에 — 일본어처럼 길면 줄여서 그림 밑으로 숨지 않게.
                      Positioned(
                        left: 81 * s,
                        top: 330 * s,
                        width: (illustrationAt.dx - 81 - 8) * s,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.onboardingHeaderTitle,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 64 * s,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 6 * s),
                              Text(
                                l10n.onboardingHeaderDesc,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 38 * s,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const DesignPositioned(
                        left: -1,
                        top: 629,
                        child: ArtImage(
                          OnboardingArt.cardTop,
                          width: 1083,
                          height: 365,
                        ),
                      ),
                      ..._progress(s),
                      DesignPositioned(
                        left: 419,
                        top: 839,
                        child: switch (OnboardingArt.stepBadge(step)) {
                          final String badge => ArtImage(
                            badge,
                            width: 239,
                            height: 104,
                          ),
                          null => _StepBadgePlaceholder(step: step, scale: s),
                        },
                      ),
                      _centered(
                        s,
                        top: questionTop,
                        // 한 줄로 — 일본어처럼 길면 줄여서 아래 칸을 밀어내지 않게.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            question,
                            maxLines: 1,
                            style: TextStyle(
                              color: OnboardingArt.ink,
                              fontSize: 64 * s,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      ...?content?.call(s),
                      if (note != null)
                        _centered(
                          s,
                          top: noteTop!,
                          child: Text(
                            note!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: OnboardingArt.gray,
                              fontSize: 40 * s,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (body != null) Expanded(child: body!) else const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  127 * s,
                  0,
                  (1080 - 779 - 170) * s,
                  bottomGap,
                ),
                child: Row(
                  children: [
                    if (onBack != null)
                      GestureDetector(
                        onTap: onBack,
                        child: const ArtImage(
                          OnboardingArt.back,
                          width: 172,
                          height: 171,
                        ),
                      ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _next(context),
                      child: const ArtImage(
                        OnboardingArt.next,
                        width: 170,
                        height: 171,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 진행 표시 — 지난 단계 ✓ · 지금 단계 ◎ · 남은 단계 ○, 사이 선은 지난 쪽만 채운다.
  List<Widget> _progress(double s) {
    const total = 7;
    final out = <Widget>[];
    for (var i = 0; i < total - 1; i++) {
      final cx =
          (OnboardingArt.markCenterX(i) + OnboardingArt.markCenterX(i + 1)) / 2;
      out.add(
        DesignPositioned(
          left: cx - 20,
          top: OnboardingArt.markCenterY - 2,
          child: ArtImage(
            i < step - 1 ? OnboardingArt.barFill : OnboardingArt.barUnfill,
            width: 40,
            height: 4,
          ),
        ),
      );
    }
    for (var i = 0; i < total; i++) {
      final (asset, d) = i < step - 1
          ? (OnboardingArt.markComplete, 58.0)
          : i == step - 1
          ? (OnboardingArt.markProgress, 50.0)
          : (OnboardingArt.markPending, 43.0);
      out.add(
        DesignPositioned(
          left: OnboardingArt.markCenterX(i) - d / 2,
          top: OnboardingArt.markCenterY - d / 2,
          child: ArtImage(asset, width: d, height: d),
        ),
      );
    }
    return out;
  }

  static Widget _centered(
    double s, {
    required double top,
    required Widget child,
  }) => Positioned(
    left: 40 * s,
    right: 40 * s,
    top: top * s,
    child: Center(child: child),
  );
}

/// `STEP n` 배지 그림이 아직 없는 단계의 자리 표시 — 같은 자리·크기(239×104)의 보라 알약 + 흰 글자.
/// 🚧 `icon_porfile_step{n}.png`가 오면 [OnboardingArt.stepBadge]에 한 줄 더하면 이 위젯은 안 쓰인다.
class _StepBadgePlaceholder extends StatelessWidget {
  const _StepBadgePlaceholder({required this.step, required this.scale});

  final int step;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      width: 239 * s,
      height: 104 * s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: OnboardingArt.purple,
        borderRadius: BorderRadius.circular(52 * s),
      ),
      child: Text(
        'STEP $step',
        style: TextStyle(
          color: Colors.white,
          fontSize: 46 * s,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
