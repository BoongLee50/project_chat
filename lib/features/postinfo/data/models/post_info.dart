/// [포스트 정보] 화면 1건. (기획 6-1 · 7-1)
///
/// 대화방의 받은 신청 카드, 친구 목록 카드, 달빛가든이 **같은 화면**을 부른다.
/// 보여 주는 건 똑같고 **하단 버튼만** 다르므로, 서버 응답도 하나다.
class PostInfo {
  const PostInfo({
    required this.userId,
    required this.nickname,
    this.age,
    this.country,
    this.gender,
    this.online = false,
    this.premium = false,
    this.photoUrls = const [],
    this.photoLocked = false,
    this.totalPhotos = 0,
    this.hasTodayPost = false,
    this.profilePhotoUrl,
    this.intro,
    this.interests = const [],
    this.regions = const [],
    this.chatRequestId,
    this.chatRequestMessage,
    this.friendRelation = FriendRelation.none,
    this.friendshipId,
    this.friendRequestMessage,
    this.chatRoomId,
  });

  final String userId;
  final String nickname;
  final int? age;
  final String? country;
  final String? gender;
  final bool online;
  final bool premium;

  /// 실제로 볼 수 있는 사진. **열람 제한이 걸리면 메인 1장만 온다**(서버가 자른다).
  final List<String> photoUrls;
  final bool photoLocked;

  /// 원래 몇 장인가 — `1/9` 표기는 이 값을 쓴다.
  final int totalPhotos;

  /// 오늘 포스트가 있는가. 없으면 [photoUrls]는 프로필 사진 한 장이다.
  final bool hasTodayPost;
  final String? profilePhotoUrl;

  final String? intro;
  final List<String> interests;

  /// 활동 지역 **코드**. 문구는 `ProfileCatalog.regionLabel`이 만든다.
  final List<String> regions;

  /// 상대가 나에게 보낸 대화 신청. 있으면 하단이 [거절]/[수락]이 된다.
  final String? chatRequestId;
  final String? chatRequestMessage;

  final FriendRelation friendRelation;
  final String? friendshipId;

  /// 상대가 친구 신청과 함께 남긴 한마디(25자).
  /// 대화 신청 메시지와 **같은 자리**에 보여 준다 — 시안이 그렇다.
  final String? friendRequestMessage;

  /// 지금 살아 있는 대화방. 있으면 하단이 [대화하기]가 된다.
  final String? chatRoomId;

  /// 따옴표 칸에 넣을 말. 대화 신청이 먼저다 — 답해야 할 쪽이 그쪽이다.
  String? get quotedMessage {
    final chat = chatRequestMessage;
    if (chat != null && chat.isNotEmpty) return chat;
    final friend = friendRequestMessage;
    return (friend != null && friend.isNotEmpty) ? friend : null;
  }

  static PostInfo fromJson(Map<String, dynamic> json) => PostInfo(
    userId: json['userId'] as String,
    nickname: (json['nickname'] as String?) ?? '',
    age: json['age'] as int?,
    country: json['country'] as String?,
    gender: json['gender'] as String?,
    online: json['online'] as bool? ?? false,
    premium: json['premium'] as bool? ?? false,
    photoUrls: (json['photoUrls'] as List?)?.cast<String>() ?? const [],
    photoLocked: json['photoLocked'] as bool? ?? false,
    totalPhotos: json['totalPhotos'] as int? ?? 0,
    hasTodayPost: json['hasTodayPost'] as bool? ?? false,
    profilePhotoUrl: json['profilePhotoUrl'] as String?,
    intro: json['intro'] as String?,
    interests: (json['interests'] as List?)?.cast<String>() ?? const [],
    regions: (json['regions'] as List?)?.cast<String>() ?? const [],
    chatRequestId: json['chatRequestId'] as String?,
    chatRequestMessage: json['chatRequestMessage'] as String?,
    friendRelation: FriendRelation.parse(json['friendRelation'] as String?),
    friendshipId: json['friendshipId'] as String?,
    friendRequestMessage: json['friendRequestMessage'] as String?,
    chatRoomId: json['chatRoomId'] as String?,
  );
}

/// 친구 관계 4상태. 대화방·친구 목록의 관계 버튼이 이걸 보고 글자를 고른다.
///
/// `friendships`에 REJECTED가 없는 건 **거절하면 행을 지우기** 때문이다(02 §1.6) —
/// 그래서 "없음"과 "거절당함"은 구분되지 않고, 구분할 이유도 없다.
enum FriendRelation {
  /// 아무 사이도 아니다 → [친구 신청]
  none,

  /// 내가 보냈고 답을 기다린다 → [신청 대기]
  requested,

  /// 상대가 보냈고 내가 답할 차례다 → [친구 수락]
  incoming,

  /// 이미 친구다 → [친구]
  friend;

  static FriendRelation parse(String? value) => switch (value) {
    'REQUESTED' => FriendRelation.requested,
    'INCOMING' => FriendRelation.incoming,
    'FRIEND' => FriendRelation.friend,
    _ => FriendRelation.none,
  };
}
