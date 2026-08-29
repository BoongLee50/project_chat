// 오늘의 포스트 DTO. (docs/01-protocol-api-spec.md §1.3)

class PostPhoto {
  const PostPhoto({
    required this.id,
    required this.url,
    required this.orderIdx,
  });

  final String id;

  /// 서버가 준 다운로드 URL(로컬 스토리지 모드에서는 `/files?key=...` 상대경로).
  final String url;

  final int orderIdx;

  factory PostPhoto.fromJson(Map<String, dynamic> json) => PostPhoto(
    id: json['id'] as String,
    url: json['url'] as String,
    orderIdx: json['orderIdx'] as int? ?? 0,
  );
}

class MyPost {
  const MyPost({
    required this.sessionDate,
    required this.photos,
    required this.mainPhotoId,
    required this.published,
    required this.maxPhotos,
    required this.replaceRemaining,
  });

  /// 영업일. **Plan_3부터 KST 18시에 넘어간다**(서버 `app.session.rollover-hour`).
  final String sessionDate;

  /// 표시 순서. **1번 슬롯이 최신**이다(Plan_3 §3-1) — 서버가 그 순서로 준다.
  final List<PostPhoto> photos;

  /// 달빛가든에 노출할 대표 사진. 사진이 없으면 null.
  ///
  /// 서버가 항상 **존재하는 사진**을 가리키도록 정리해서 준다(떠 있으면 첫 슬롯으로 대신).
  /// 최초 사진은 자동 메인이고, 메인을 지우면 이웃 슬롯이 승계된다.
  final String? mainPhotoId;

  final bool published;

  /// 등록 가능한 최대 사진 수. 무료·앨범패스에 따라 서버가 정해 준다.
  final int maxPhotos;
  final int replaceRemaining;

  /// 사진을 더 등록할 수 있는 상태인가.
  bool get canAddPhoto => addPhotoBlockedReason == null;

  /// 사진을 못 올리는 **이유**. 올릴 수 있으면 null.
  ///
  /// 버튼을 그냥 죽여 두면 사용자는 고장으로 여긴다 —
  /// 눌렀을 때 이유를 알려주려고 조건을 코드로 나눠 둔다.
  /// 서버 `ErrorCode`와 같은 이름을 써서 문구를 그대로 재사용한다.
  /// Plan_3에서 **운영시간 게이트와 등록 창(1시간)이 폐지**돼 남은 이유는 장수 초과뿐이다.
  String? get addPhotoBlockedReason {
    if (photos.length >= maxPhotos) return 'POST_PHOTO_LIMIT';
    return null;
  }

  factory MyPost.fromJson(Map<String, dynamic> json) => MyPost(
    sessionDate: json['sessionDate'] as String? ?? '',
    photos: (json['photos'] as List? ?? const [])
        .map((e) => PostPhoto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    mainPhotoId: json['mainPhotoId'] as String?,
    published: json['published'] as bool? ?? false,
    maxPhotos: json['maxPhotos'] as int? ?? 2,
    replaceRemaining: json['replaceRemaining'] as int? ?? 0,
  );
}
