// 달빛가든 피드 DTO. (docs/01-protocol-api-spec.md §1.4)

class FeedItem {
  const FeedItem({
    required this.userId,
    required this.nickname,
    required this.photoUrls,
    required this.interests,
    required this.likes,
    required this.comments,
    required this.pick,
    required this.online,
    this.age,
    this.country,
    this.intro,
    this.score = 0,
  });

  final String userId;
  final String nickname;
  final int? age;

  /// KR | JP
  final String? country;

  /// 부스팅(PICK) 마크 대상.
  final bool pick;

  /// 접속 중 표시.
  final bool online;

  final String? intro;

  /// 서버가 준 사진 URL(상대경로) 목록.
  final List<String> photoUrls;

  final List<String> interests;
  final int likes;
  final int comments;

  /// 정렬에 쓰인 Post Score(검증용).
  final int score;

  String get flag => switch (country) {
    'KR' => '🇰🇷',
    'JP' => '🇯🇵',
    _ => '',
  };

  factory FeedItem.fromJson(Map<String, dynamic> json) => FeedItem(
    userId: json['userId'] as String,
    nickname: json['nickname'] as String? ?? '',
    age: json['age'] as int?,
    country: json['country'] as String?,
    pick: json['pick'] as bool? ?? false,
    online: json['online'] as bool? ?? false,
    intro: json['intro'] as String?,
    photoUrls: (json['photoUrls'] as List? ?? const []).cast<String>(),
    interests: (json['interests'] as List? ?? const []).cast<String>(),
    likes: json['likes'] as int? ?? 0,
    comments: json['comments'] as int? ?? 0,
    score: json['score'] as int? ?? 0,
  );
}

class FeedPage {
  const FeedPage({required this.items, this.nextCursor});

  final List<FeedItem> items;
  final String? nextCursor;

  factory FeedPage.fromJson(Map<String, dynamic> json) => FeedPage(
    items: (json['items'] as List? ?? const [])
        .map((e) => FeedItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );
}

/// 포스트 댓글.
class Comment {
  const Comment({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    required this.body,
  });

  final String id;
  final String authorId;
  final String authorNickname;
  final String body;

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as String,
    authorId: json['authorId'] as String? ?? '',
    authorNickname: json['authorNickname'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );
}

/// 피드 필터(기본값은 모두 [전체] = null).
class FeedFilter {
  const FeedFilter({this.gender, this.ageDecade, this.country});

  /// MALE | FEMALE
  final String? gender;

  /// 10 | 20 | 30 | 40 (연령대 앞자리)
  final int? ageDecade;

  /// KR | JP
  final String? country;

  FeedFilter copyWith({
    String? gender,
    int? ageDecade,
    String? country,
    bool clearGender = false,
    bool clearAge = false,
    bool clearCountry = false,
  }) => FeedFilter(
    gender: clearGender ? null : (gender ?? this.gender),
    ageDecade: clearAge ? null : (ageDecade ?? this.ageDecade),
    country: clearCountry ? null : (country ?? this.country),
  );
}
