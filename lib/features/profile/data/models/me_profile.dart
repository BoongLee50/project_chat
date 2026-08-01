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
  final String? photoUrl;
  final String? intro;
  final List<String> interests;
  final List<String> regions;

  /// 필수 프로필(닉네임·출생년도·성별·국가)이 모두 채워졌는가.
  bool get isComplete =>
      nickname != null && birthYear != null && gender != null && country != null;

  factory MeProfile.fromJson(Map<String, dynamic> json) => MeProfile(
    id: json['id'] as String,
    nickname: json['nickname'] as String?,
    birthYear: json['birthYear'] as int?,
    gender: json['gender'] as String?,
    country: json['country'] as String?,
    premium: json['premium'] as bool? ?? false,
    photoUrl: json['photoUrl'] as String?,
    intro: json['intro'] as String?,
    interests: (json['interests'] as List?)?.cast<String>() ?? const [],
    regions: (json['regions'] as List?)?.cast<String>() ?? const [],
  );
}
