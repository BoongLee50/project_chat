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

  /// `STEP n` 배지(239×104). 지금은 1~3만 왔다.
  static String stepBadge(int step) => switch (step) {
    1 => '$_s1/icon_porfile_step1.png',
    2 => '$_s2/icon_porfile_step2.png',
    _ => '$_s3/icon_porfile_step3.png',
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
    required this.note,
    required this.noteTop,
    required this.content,
    required this.onBack,
    required this.onNext,
  });

  /// 1~7.
  final int step;

  final String illustration;
  final Offset illustrationAt;
  final Size illustrationSize;

  final String question;
  final double questionTop;
  final String note;
  final double noteTop;

  /// 이 단계만의 조각들 — 시안 좌표로 `Positioned`를 돌려준다(배율 s를 받는다).
  final List<Widget> Function(double s) content;

  final VoidCallback onBack;

  /// 다음으로 — 못 넘어가면 이유 문구를, 넘어가면 null을 돌려준다.
  final Future<String?> Function() onNext;

  /// 안내 문구 아래 여백까지가 위쪽 판의 높이다.
  double get _topHeight => noteTop + 100;

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
              SizedBox(
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
                      child: ArtImage(
                        OnboardingArt.stepBadge(step),
                        width: 239,
                        height: 104,
                      ),
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
                    ...content(s),
                    _centered(
                      s,
                      top: noteTop,
                      child: Text(
                        note,
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
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  127 * s,
                  0,
                  (1080 - 779 - 170) * s,
                  bottomGap,
                ),
                child: Row(
                  children: [
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
