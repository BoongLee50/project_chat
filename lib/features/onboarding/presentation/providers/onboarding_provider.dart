import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../profile/data/models/profile_catalog.dart';

/// 온보딩(가입 정보 입력)에서 모은 값 — 그래픽 소스 `로그인 화면` 일곱 단계(2026-11-21).
///
/// STEP 1 성별 · 2 생년월일 · 3 거주 국가·지역 · 4 관심사 · 5 자기소개 · 6 닉네임 · 7 프로필 사진.
/// 🚧 지금 그림이 온 것은 **1~4**뿐이다. 5·7은 아직 화면이 없어 건너뛰고(프로필에서 나중에 채운다),
/// 6 닉네임은 **옛 닉네임 화면을 임시로** 마지막에 둔다 — 서버 `POST /profile`에 닉네임이 꼭 필요해서다.
class OnboardingForm {
  const OnboardingForm({
    this.gender,
    this.birthDate,
    this.country,
    this.region,
    this.interests = const [],
    this.nickname,
    this.busy = false,
    this.error,
  });

  /// MALE | FEMALE
  final String? gender;

  /// 생년월일(시각은 버린다).
  final DateTime? birthDate;

  /// 거주 국가 KR | JP — `users.country`가 된다(앱 언어와는 다른 것).
  final String? country;

  /// 거주 지역 코드(`KR_SEOUL` …) — 프로필의 **활동 지역 1곳**으로 저장한다.
  final String? region;

  /// 관심사 코드(최대 [ProfileCatalog.maxInterests]개, 고른 순서) — 프로필 관심사로 그대로 저장한다.
  final List<String> interests;

  final String? nickname;

  final bool busy;
  final String? error;

  OnboardingForm copyWith({
    String? gender,
    DateTime? birthDate,
    String? country,
    String? region,
    bool clearRegion = false,
    List<String>? interests,
    String? nickname,
    bool? busy,
    String? error,
  }) => OnboardingForm(
    gender: gender ?? this.gender,
    birthDate: birthDate ?? this.birthDate,
    country: country ?? this.country,
    region: clearRegion ? null : (region ?? this.region),
    interests: interests ?? this.interests,
    nickname: nickname ?? this.nickname,
    busy: busy ?? this.busy,
    error: error,
  );
}

class OnboardingController extends Notifier<OnboardingForm> {
  @override
  OnboardingForm build() => const OnboardingForm();

  void setGender(String gender) => state = state.copyWith(gender: gender);

  void setBirthDate(DateTime date) => state = state.copyWith(birthDate: date);

  /// 나라를 바꾸면 고른 지역은 비운다 — 다른 나라의 지역이 남으면 안 된다.
  void setCountry(String country) => state = state.copyWith(
    country: country,
    clearRegion: country != state.country,
  );

  void setRegion(String region) => state = state.copyWith(region: region);

  /// 관심사 한 개를 넣거나 뺀다. 한도는 화면이 먼저 막고 이유를 말한다 — 여기서는 넘치면 무시한다.
  void toggleInterest(String code) {
    final now = state.interests;
    if (now.contains(code)) {
      state = state.copyWith(interests: [...now]..remove(code));
    } else if (now.length < ProfileCatalog.maxInterests) {
      state = state.copyWith(interests: [...now, code]);
    }
  }

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

  /// 프로필 생성 요청 → 거주 지역·관심사 저장 → 세션을 authenticated로 전환.
  ///
  /// ⚠️ 지역·관심사는 프로필이 만들어진 **뒤에** 저장한다(`PUT /me/regions` · `PUT /me/interests`). 세션 전환([completeOnboarding])이
  /// 마지막이어야 한다 — 먼저 바꾸면 라우터가 메인으로 넘어가 버린다.
  Future<bool> submitProfile() async {
    final form = state;
    if (form.nickname == null ||
        form.birthDate == null ||
        form.gender == null ||
        form.country == null) {
      state = state.copyWith(error: '입력이 완료되지 않았어요.');
      return false;
    }

    state = state.copyWith(busy: true);
    try {
      final api = ref.read(profileApiProvider);
      await api.createProfile(
        nickname: form.nickname!,
        birthDate: form.birthDate!,
        gender: form.gender!,
        country: form.country!,
      );
      if (form.region != null) await api.updateRegions([form.region!]);
      if (form.interests.isNotEmpty) await api.updateInterests(form.interests);
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
