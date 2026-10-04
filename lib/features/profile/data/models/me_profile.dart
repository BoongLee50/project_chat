/// 내 프로필. (`GET /me` — docs/01-protocol-api-spec.md §1.2)
class MeProfile {
  const MeProfile({
    required this.id,
    this.nickname,
    this.birthYear,
    this.gender,
    this.country,
    this.premium = false,
    this.photoUrl,
    this.mainPhotoUrl,
    this.intro,
    this.interests = const [],
    this.regions = const [],
  });

  final String id;
  final String? nickname;
  final int? birthYear;

  /// MALE | FEMALE
  final String? gender;

  /// KR | JP
  final String? country;

  final bool premium;

  /// **얼굴 사진** — 친구·대화 목록 같은 간략한 목록이 쓴다(기획서 261002 8-1 첫째 칸).
  final String? photoUrl;

  /// **자유 사진** — [미리 보기]의 큰 메인 사진(8-1 둘째 칸, V28).
  final String? mainPhotoUrl;
  final String? intro;
  final List<String> interests;
  final List<String> regions;

  /// 필수 프로필(닉네임·출생년도·성별·국가)이 모두 채워졌는가.
  bool get isComplete =>
      nickname != null &&
      birthYear != null &&
      gender != null &&
      country != null;

  /// [작성하기]의 네 단계(사진·자기소개·관심사·활동 지역) 중 끝낸 수 — 한 단계가 25%다(8-1).
  ///
  /// 사진 단계는 **두 칸을 다 채워야** 끝난다 — 안내가 "한 장씩을 담아 주세요"이고,
  /// 한 칸만 차면 미리 보기의 얼굴이나 메인 사진 한쪽이 빈다.
  int get filledSteps => [
    photoUrl != null && mainPhotoUrl != null,
    intro != null && intro!.trim().isNotEmpty,
    interests.isNotEmpty,
    regions.isNotEmpty,
  ].where((done) => done).length;

  factory MeProfile.fromJson(Map<String, dynamic> json) => MeProfile(
    id: json['id'] as String,
    nickname: json['nickname'] as String?,
    birthYear: json['birthYear'] as int?,
    gender: json['gender'] as String?,
    country: json['country'] as String?,
    premium: json['premium'] as bool? ?? false,
    photoUrl: json['photoUrl'] as String?,
    mainPhotoUrl: json['mainPhotoUrl'] as String?,
    intro: json['intro'] as String?,
    interests: (json['interests'] as List?)?.cast<String>() ?? const [],
    regions: (json['regions'] as List?)?.cast<String>() ?? const [],
  );
}
