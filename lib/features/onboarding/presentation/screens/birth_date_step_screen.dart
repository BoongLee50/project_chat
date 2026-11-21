import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_frame.dart';

/// 온보딩 STEP 2 — 생년월일(`그래픽 소스\로그인 화면\2. 생년월일 작성 화면`).
///
/// `YYYY / MM / DD` 여덟 칸 — 숫자는 **글자**(보라, 값이 변한다), 밑줄·사선·`AGE`는 그림.
/// 보이지 않는 숫자 입력칸 하나가 자판을 받고 칸마다 한 글자씩 그린다. 여덟 자를 채우면 자판을 내린다.
/// 날짜가 맞으면 아래에 `AGE nn`(만 나이)을 보여 준다. 만 18세 미만은 넘어가지 않고 이유를 말한다
/// (서버도 같은 검사를 한다 — `AGE_RESTRICTED`).
class BirthDateStepScreen extends ConsumerStatefulWidget {
  const BirthDateStepScreen({super.key});

  @override
  ConsumerState<BirthDateStepScreen> createState() =>
      _BirthDateStepScreenState();
}

class _BirthDateStepScreenState extends ConsumerState<BirthDateStepScreen> {
  static const _minAge = 18;

  /// 밑줄 왼쪽 x — 연 4 · 월 2 · 일 2(시안 실측, y 1377).
  static const _slots = <double>[96, 184, 272, 362, 549, 639, 824, 916];

  late final TextEditingController _digits = TextEditingController(
    text: _initialDigits(ref.read(onboardingProvider).birthDate),
  );
  final FocusNode _focus = FocusNode();

  static String _initialDigits(DateTime? d) => d == null
      ? ''
      : '${d.year.toString().padLeft(4, '0')}'
            '${d.month.toString().padLeft(2, '0')}'
            '${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _digits.addListener(() {
      setState(() {});
      if (_digits.text.length == 8) _focus.unfocus();
    });
  }

  /// 숫자 칸을 누르면 자판을 연다.
  ///
  /// ⚠️ 안드로이드 뒤로 키는 자판만 내리고 **포커스는 남긴다**(함정 #88) — 그 상태에서 `requestFocus()`는
  /// 아무 일도 안 해서 다시 눌러도 자판이 안 올라왔다(실기 확인). 포커스가 있으면 자판만 다시 띄운다.
  void _openKeyboard() {
    if (_focus.hasFocus) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    } else {
      _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    _digits.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// 여덟 자가 실제 있는 날짜면 그 날짜, 아니면 null(2월 30일 같은 것도 null).
  DateTime? get _date {
    final t = _digits.text;
    if (t.length != 8) return null;
    final y = int.parse(t.substring(0, 4));
    final m = int.parse(t.substring(4, 6));
    final d = int.parse(t.substring(6, 8));
    final date = DateTime(y, m, d);
    if (y < 1900 || date.year != y || date.month != m || date.day != d) {
      return null;
    }
    if (date.isAfter(DateTime.now())) return null;
    return date;
  }

  static int _ageOf(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final date = _date;
    final age = date == null ? null : _ageOf(date);

    return OnboardingFrame(
      step: 2,
      illustration: OnboardingArt.illustAge,
      illustrationAt: const Offset(513, 198),
      illustrationSize: const Size(512, 361),
      question: l10n.onboardingBirthQuestion,
      questionTop: 1040,
      note: l10n.onboardingBirthNote,
      noteTop: 1462,
      content: (s) => [
        // 숫자 칸 전체를 누르면 자판이 올라온다.
        Positioned(
          left: 60 * s,
          top: 1200 * s,
          width: 960 * s,
          height: 200 * s,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openKeyboard,
          ),
        ),
        for (var i = 0; i < _slots.length; i++) ...[
          DesignPositioned(
            left: _slots[i],
            top: 1377,
            child: const ArtImage(
              OnboardingArt.underline,
              width: 66,
              height: 14,
            ),
          ),
          if (i < _digits.text.length)
            Positioned(
              left: (_slots[i] + 33 - 50) * s,
              top: 1222 * s,
              width: 100 * s,
              child: IgnorePointer(
                child: Text(
                  _digits.text[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: OnboardingArt.purple,
                    fontSize: 134 * s,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
        const DesignPositioned(
          left: 457,
          top: 1262,
          child: ArtImage(OnboardingArt.slash, width: 59, height: 96),
        ),
        const DesignPositioned(
          left: 730,
          top: 1262,
          child: ArtImage(OnboardingArt.slash, width: 59, height: 96),
        ),
        if (age != null) ...[
          const DesignPositioned(
            left: 284,
            top: 1670,
            child: ArtImage(OnboardingArt.ageLabel, width: 286, height: 115),
          ),
          Positioned(
            left: 600 * s,
            top: 1650 * s,
            child: Text(
              '$age',
              style: TextStyle(
                color: OnboardingArt.purple,
                fontSize: 158 * s,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        ],
        // 자판을 받는 보이지 않는 입력칸.
        Positioned(
          left: 0,
          top: 1300 * s,
          width: 1,
          height: 1,
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _digits,
              focusNode: _focus,
              autofocus: _digits.text.isEmpty,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              showCursor: false,
              enableInteractiveSelection: false,
            ),
          ),
        ),
      ],
      onBack: () => context.go(Routes.onboardingGender),
      // 자판은 `AGE`(1670)부터만 가린다 — 숫자 칸·안내 문구는 늘 보이게(사용자 2026-11-21).
      keyboardLimit: 1650,
      onNext: () async {
        if (date == null) return l10n.onboardingBirthInvalid;
        if (age! < _minAge) return l10n.errorAgeRestricted;
        ref.read(onboardingProvider.notifier).setBirthDate(date);
        if (context.mounted) context.go(Routes.onboardingResidence);
        return null;
      },
    );
  }
}
