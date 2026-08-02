import '../../../../core/util/server_time.dart';

// 친구 DTO. 친구는 양방향(상호 동의) — 요청 후 상대 수락으로 성립한다.
// (docs/01-protocol-api-spec.md §1.7, docs/02-db-schema.md §1.6)

class Friend {
  const Friend({
    required this.friendshipId,
    required this.userId,
    required this.nickname,
    required this.online,
    this.age,
    this.gender,
    this.country,
    this.intro,
    this.photoUrl,
    this.roomId,
  });

  final String friendshipId;
  final String userId;
  final String nickname;

  /// 수락 시 만들어지는 상시 대화방. 운영시간(17~06시) 밖에도 유지된다.
  final String? roomId;

  final bool online;
  final int? age;
  final String? gender;
  final String? country;
  final String? intro;
  final String? photoUrl;

  String get flag => switch (country) {
    'KR' => '🇰🇷',
    'JP' => '🇯🇵',
    _ => '',
  };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
    friendshipId: json['friendshipId'] as String,
    userId: json['userId'] as String? ?? '',
    nickname: json['nickname'] as String? ?? '',
    roomId: json['roomId'] as String?,
    online: json['online'] as bool? ?? false,
    age: json['age'] as int?,
    gender: json['gender'] as String?,
    country: json['country'] as String?,
    intro: json['intro'] as String?,
    photoUrl: json['photoUrl'] as String?,
  );
}

/// 친구 요청(받은/보낸 공용).
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.partnerNickname,
    this.partnerAge,
    this.partnerCountry,
    this.partnerPhotoUrl,
  });

  final String id;
  final String requesterId;
  final String addresseeId;

  /// PENDING | ACCEPTED
  final String status;

  final String partnerNickname;
  final int? partnerAge;
  final String? partnerCountry;
  final String? partnerPhotoUrl;

  String get flag => switch (partnerCountry) {
    'KR' => '🇰🇷',
    'JP' => '🇯🇵',
    _ => '',
  };

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
    id: json['id'] as String,
    requesterId: json['requesterId'] as String? ?? '',
    addresseeId: json['addresseeId'] as String? ?? '',
    status: json['status'] as String? ?? 'PENDING',
    partnerNickname: json['partnerNickname'] as String? ?? '',
    partnerAge: json['partnerAge'] as int?,
    partnerCountry: json['partnerCountry'] as String?,
    partnerPhotoUrl: json['partnerPhotoUrl'] as String?,
  );
}

/// 친구 목록 필터. 값이 없으면 전체.
class FriendFilter {
  const FriendFilter({this.gender, this.ageMin, this.ageMax, this.country});

  final String? gender;
  final int? ageMin;
  final int? ageMax;
  final String? country;

  bool get isEmpty =>
      gender == null && ageMin == null && ageMax == null && country == null;

  FriendFilter copyWith({
    String? gender,
    int? ageMin,
    int? ageMax,
    String? country,
    bool clearGender = false,
    bool clearAge = false,
    bool clearCountry = false,
  }) => FriendFilter(
    gender: clearGender ? null : (gender ?? this.gender),
    ageMin: clearAge ? null : (ageMin ?? this.ageMin),
    ageMax: clearAge ? null : (ageMax ?? this.ageMax),
    country: clearCountry ? null : (country ?? this.country),
  );

  Map<String, dynamic> toQuery() => {
    if (gender != null) 'gender': gender,
    if (ageMin != null) 'ageMin': ageMin,
    if (ageMax != null) 'ageMax': ageMax,
    if (country != null) 'country': country,
  };

  @override
  bool operator ==(Object other) =>
      other is FriendFilter &&
      other.gender == gender &&
      other.ageMin == ageMin &&
      other.ageMax == ageMax &&
      other.country == country;

  @override
  int get hashCode => Object.hash(gender, ageMin, ageMax, country);
}

/// 친구의 오늘 포스트. (기획서 화면 19, docs/01 §1.7)
class FriendPost {
  const FriendPost({
    required this.userId,
    required this.nickname,
    required this.pick,
    required this.online,
    required this.photoUrls,
    required this.likes,
    required this.comments,
    this.age,
    this.country,
    this.oneLiner,
    this.publishedAt,
  });

  final String userId;
  final String nickname;

  /// 지금 부스트를 켜 둔 상태(피드의 PICK 마크와 같은 기준).
  final bool pick;

  final bool online;
  final List<String> photoUrls;
  final int likes;
  final int comments;
  final int? age;
  final String? country;
  final String? oneLiner;
  final DateTime? publishedAt;

  String get flag => switch (country) {
    'KR' => '🇰🇷',
    'JP' => '🇯🇵',
    _ => '',
  };

  factory FriendPost.fromJson(Map<String, dynamic> json) => FriendPost(
    userId: json['userId'] as String? ?? '',
    nickname: json['nickname'] as String? ?? '',
    pick: json['pick'] as bool? ?? false,
    online: json['online'] as bool? ?? false,
    photoUrls: (json['photoUrls'] as List? ?? const [])
        .map((e) => e as String)
        .toList(),
    likes: json['likes'] as int? ?? 0,
    comments: json['comments'] as int? ?? 0,
    age: json['age'] as int?,
    country: json['country'] as String?,
    oneLiner: json['oneLiner'] as String?,
    publishedAt: parseServerTime(json['publishedAt']),
  );
}
