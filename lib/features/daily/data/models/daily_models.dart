// 달빛 한마디 DTO. (기획서 8장 / docs/01 §1.9)
//
// 이름에 콘텐츠를 넣지 않는다 — "달빛우편"이 "달빛 한마디"가 된 전례가 있어
// 코드는 `daily*` 라는 역할 이름을 쓰고, 화면 문구만 ARB에서 온다.

/// [타이틀] 화면 — 오늘의 질문·참여 인원·남은 시간.
class DailyToday {
  const DailyToday({
    required this.questionId,
    required this.question,
    required this.participants,
    required this.remainingSeconds,
    required this.answered,
    this.myAnswerId,
  });

  final String questionId;
  final String question;
  final int participants;

  /// 다음 초기화(KST 18시)까지 남은 초. **서버가 계산해 준다** —
  /// 기기 시계를 믿으면 사람마다 다른 시간이 보인다.
  final int remainingSeconds;

  final bool answered;
  final String? myAnswerId;

  factory DailyToday.fromJson(Map<String, dynamic> json) => DailyToday(
    questionId: json['questionId'] as String? ?? '',
    question: json['question'] as String? ?? '',
    participants: json['participants'] as int? ?? 0,
    remainingSeconds: json['remainingSeconds'] as int? ?? 0,
    answered: json['answered'] as bool? ?? false,
    myAnswerId: json['myAnswerId'] as String?,
  );
}

/// 달빛 한마디 한 건.
class DailyAnswer {
  const DailyAnswer({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.body,
    required this.likes,
    required this.comments,
    required this.likedByMe,
    required this.mine,
    this.age,
    this.country,
    this.imageUrl,
  });

  final String id;
  final String userId;
  final String nickname;
  final int? age;
  final String? country;
  final String body;
  final String? imageUrl;
  final int likes;
  final int comments;

  /// 내가 좋아요를 눌렀는가. 사람마다 한 번이라 누른 뒤에는 눌린 상태로 둔다.
  final bool likedByMe;
  final bool mine;

  String get flag => switch (country) {
    'KR' => '🇰🇷',
    'JP' => '🇯🇵',
    _ => '',
  };

  factory DailyAnswer.fromJson(Map<String, dynamic> json) => DailyAnswer(
    id: json['id'] as String,
    userId: json['userId'] as String? ?? '',
    nickname: json['nickname'] as String? ?? '',
    age: json['age'] as int?,
    country: json['country'] as String?,
    body: json['body'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    likes: json['likes'] as int? ?? 0,
    comments: json['comments'] as int? ?? 0,
    likedByMe: json['likedByMe'] as bool? ?? false,
    mine: json['mine'] as bool? ?? false,
  );
}

/// 목록 정렬. 기본은 최신순, 인기순은 **좋아요 + 댓글 합**이다(기획 8-1).
enum DailySort { latest, popular }
