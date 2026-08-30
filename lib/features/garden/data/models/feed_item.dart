// 달빛가든 피드 DTO. (docs/01-protocol-api-spec.md §1.4)

class FeedItem {
  const FeedItem({
    required this.userId,
    required this.nickname,
    required this.photoUrls,
    required this.photoLocked,
    required this.totalPhotos,
    required this.interests,
    required this.likes,
    required this.comments,
    required this.likedByMe,
    required this.pick,
    required this.online,
    this.age,
    this.country,
    this.intro,
    this.region,
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

  /// 활동 지역 **코드** 1개. "한국, 서울" 문구는 `ProfileCatalog.regionLabel`이 만든다.
  final String? region;

  /// 서버가 준 사진 URL(상대경로) 목록.
  ///
  /// **열람 제한이 걸리면 메인 1장만 들어 있다.** 잠긴 사진의 URL은 아예 오지 않으므로
  /// 화면이 가리는 게 아니라 **애초에 받지 못한다**(서버가 자른다).
  final List<String> photoUrls;

  /// 나머지 사진이 잠겨 있는가. 오늘 내 포스트를 공유하면 열린다.
  final bool photoLocked;

  /// 원래 몇 장인지. 잠겨 있어도 "더 있다"를 보여줘야 안내가 말이 된다.
  final int totalPhotos;

  /// 잠금 때문에 못 보고 있는 장수.
  int get lockedPhotoCount =>
      photoLocked ? (totalPhotos - photoUrls.length).clamp(0, totalPhotos) : 0;

  final List<String> interests;
  final int likes;
  final int comments;

  /// 내가 이미 좋아요를 눌렀는가. **하루 한 번**이라 누른 뒤에는 채워진 하트로 둔다.
  final bool likedByMe;

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
    region: json['region'] as String?,
    photoUrls: (json['photoUrls'] as List? ?? const []).cast<String>(),
    photoLocked: json['photoLocked'] as bool? ?? false,
    totalPhotos: json['totalPhotos'] as int? ?? 0,
    interests: (json['interests'] as List? ?? const []).cast<String>(),
    likes: json['likes'] as int? ?? 0,
    comments: json['comments'] as int? ?? 0,
    likedByMe: json['likedByMe'] as bool? ?? false,
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

/// 포스트 댓글(기획 4-2). **3단계**까지 · 50자 · 이미지 1장.
///
/// 서버가 **트리 순서로 평탄화**해서 준다 — 부모 바로 뒤에 그 답글이 오므로
/// 화면은 [depth]만큼 들여쓰기만 하면 된다.
class Comment {
  const Comment({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    required this.body,
    this.parentId,
    this.depth = 1,
    this.imageUrl,
  });

  final String id;
  final String authorId;
  final String authorNickname;
  final String body;

  /// 부모 댓글. 1단계면 null.
  final String? parentId;

  /// 1=댓글, 2=대댓글, 3=대대댓글.
  final int depth;

  /// 첨부 이미지(없으면 null). 서버 상대경로라 [AuthedImage]로 그린다.
  final String? imageUrl;

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as String,
    authorId: json['authorId'] as String? ?? '',
    authorNickname: json['authorNickname'] as String? ?? '',
    body: json['body'] as String? ?? '',
    parentId: json['parentId'] as String?,
    depth: json['depth'] as int? ?? 1,
    imageUrl: json['imageUrl'] as String?,
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
