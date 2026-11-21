import 'package:flutter_test/flutter_test.dart';
import 'package:project_chat/features/onboarding/presentation/widgets/onboarding_frame.dart';

/// 생년월일 STEP 2 — 자판은 `AGE`(시안 1650 선) 아래만 가린다(사용자 2026-11-21).
/// 기기마다 자판 높이가 달라 고정 값이 아니라 **지금 자판 높이**로 올릴 만큼을 센다.
void main() {
  double lift({
    required double screenH,
    required double keyboard,
    double scale = 0.36,
  }) => OnboardingFrame.keyboardLiftFor(
    limit: 1650,
    scale: scale,
    keyboard: keyboard,
    keyboardTop: screenH - keyboard,
  );

  test('자판이 없으면 안 움직인다', () {
    expect(lift(screenH: 900, keyboard: 0), 0);
  });

  test('자판 윗변이 AGE 선보다 아래면 안 움직인다(낮은 자판)', () {
    // 선 = 1650 × 0.36 = 594. 자판 윗변 900 − 250 = 650 > 594
    expect(lift(screenH: 900, keyboard: 250), 0);
  });

  test('자판이 선을 넘으면 넘은 만큼만 올린다(높은 자판)', () {
    // 자판 윗변 900 − 400 = 500 → 594 − 500 = 94
    expect(lift(screenH: 900, keyboard: 400), closeTo(94, 0.001));
  });

  test('같은 자판이라도 화면이 짧은 기기는 더 올린다', () {
    expect(
      lift(screenH: 800, keyboard: 400),
      greaterThan(lift(screenH: 900, keyboard: 400)),
    );
  });

  test('선을 안 주면(다른 단계) 자판을 신경 쓰지 않는다', () {
    expect(
      OnboardingFrame.keyboardLiftFor(
        limit: null,
        scale: 0.36,
        keyboard: 400,
        keyboardTop: 500,
      ),
      0,
    );
  });
}
