import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../auth/presentation/providers/session_provider.dart';

/// 온보딩 3단계(닉네임 → 출생년도 → 성별/국가)에서 모은 입력값.
class OnboardingForm {
  const OnboardingForm({
    this.nickname,
    this.birthYear,
    this.gender,
    this.country,
    this.busy = false,
    this.error,
  });

  final String? nickname;
  final int? birthYear;

  /// MALE | FEMALE
  final String? gender;

  /// KR | JP
  final String? country;

  final bool busy;
  final String? error;

  OnboardingForm copyWith({
    String? nickname,
    int? birthYear,
    String? gender,
    String? country,
    bool? busy,
    String? error,
  }) => OnboardingForm(
    nickname: nickname ?? this.nickname,
    birthYear: birthYear ?? this.birthYear,
    gender: gender ?? this.gender,
    country: country ?? this.country,
    busy: busy ?? this.busy,
    error: error,
  );
}

class OnboardingController extends Notifier<OnboardingForm> {
  @override
  OnboardingForm build() => const OnboardingForm();

  /// 닉네임 중복/금지어 검사(서버 판정). 통과하면 폼에 저장하고 true.
  Future<bool> submitNickname(String value) async {
    state = state.copyWith(busy: true);
    try {
      final available = await ref
          .read(profileApiProvider)
          .isNicknameAvailable(value);
      if (!available) {
        state = state.copyWith(busy: false, error: '이미 사용중인 닉네임입니다.');
        return false;
      }
      state = state.copyWith(nickname: value, busy: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
      return false;
    }
  }

  void setBirthYear(int year) => state = state.copyWith(birthYear: year);

  void setGender(String gender) => state = state.copyWith(gender: gender);

  void setCountry(String country) => state = state.copyWith(country: country);

  /// 프로필 생성 요청 → 성공 시 세션을 authenticated로 전환.
  Future<bool> submitProfile() async {
    final form = state;
    if (form.nickname == null ||
        form.birthYear == null ||
        form.gender == null ||
        form.country == null) {
      state = state.copyWith(error: '입력이 완료되지 않았어요.');
      return false;
    }

    state = state.copyWith(busy: true);
    try {
      await ref
          .read(profileApiProvider)
          .createProfile(
            nickname: form.nickname!,
            birthYear: form.birthYear!,
            gender: form.gender!,
            country: form.country!,
          );
      await ref.read(sessionProvider.notifier).completeOnboarding();
      state = const OnboardingForm();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
      return false;
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingForm>(
      OnboardingController.new,
    );
