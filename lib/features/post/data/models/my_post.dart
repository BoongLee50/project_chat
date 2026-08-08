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
    required this.gateOpen,
    required this.photos,
    required this.published,
    required this.uploadUnlimited,
    required this.maxPhotos,
    required this.replaceRemaining,
    this.oneLiner,
    this.remainingUploadSeconds,
  });

  /// 영업일(06시 롤오버 기준).
  final String sessionDate;

  /// 지금이 운영시간(17~06시)인지.
  final bool gateOpen;

  final List<PostPhoto> photos;
  final String? oneLiner;
  final bool published;

  /// 남은 등록 가능 시간(초). 무제한(프라임/앨범패스)이면 null → "PASS" 표시.
  final int? remainingUploadSeconds;

  final bool uploadUnlimited;
  final int maxPhotos;
  final int replaceRemaining;

  /// 사진을 더 등록할 수 있는 상태인가.
  bool get canAddPhoto => addPhotoBlockedReason == null;

  /// 사진을 못 올리는 **이유**. 올릴 수 있으면 null.
  ///
  /// 버튼을 그냥 죽여 두면 사용자는 고장으로 여긴다 —
  /// 눌렀을 때 이유를 알려주려고 조건을 코드로 나눠 둔다.
  /// 서버 `ErrorCode`와 같은 이름을 써서 문구를 그대로 재사용한다.
  String? get addPhotoBlockedReason {
    if (!gateOpen) return 'POST_GATE_CLOSED';
    if (photos.length >= maxPhotos) return 'POST_PHOTO_LIMIT';
    if (!uploadUnlimited && (remainingUploadSeconds ?? 0) <= 0) {
      return 'POST_UPLOAD_WINDOW_CLOSED';
    }
    return null;
  }

  factory MyPost.fromJson(Map<String, dynamic> json) => MyPost(
    sessionDate: json['sessionDate'] as String? ?? '',
    gateOpen: json['gateOpen'] as bool? ?? false,
    photos: (json['photos'] as List? ?? const [])
        .map((e) => PostPhoto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    oneLiner: json['oneLiner'] as String?,
    published: json['published'] as bool? ?? false,
    remainingUploadSeconds: json['remainingUploadSeconds'] as int?,
    uploadUnlimited: json['uploadUnlimited'] as bool? ?? false,
    maxPhotos: json['maxPhotos'] as int? ?? 2,
    replaceRemaining: json['replaceRemaining'] as int? ?? 0,
  );
}
