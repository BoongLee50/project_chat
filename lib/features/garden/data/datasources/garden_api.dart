import '../../../../core/network/dio_client.dart';
import '../models/feed_item.dart';
import '../models/translate_access.dart';

/// 달빛가든 REST 호출. (docs/01-protocol-api-spec.md §1.4)
class GardenApi {
  const GardenApi(this._client);

  final DioClient _client;

  Future<FeedPage> feed({
    String? gender,
    int? ageDecade,
    String? country,
    String? cursor,
  }) async {
    final data = await _client.get(
      '/feed',
      query: {
        'gender': ?gender,
        'age': ?ageDecade,
        'country': ?country,
        'cursor': ?cursor,
      },
    );
    return FeedPage.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> like(String targetUserId) =>
      _client.post('/feed/$targetUserId/like');

  Future<void> skip(String targetUserId) =>
      _client.post('/feed/$targetUserId/skip');

  Future<List<Comment>> comments(String targetUserId) async {
    final data = await _client.get('/posts/$targetUserId/comments');
    return (data as List)
        .map((e) => Comment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 댓글/답글 작성. [parentId]가 있으면 답글이고, 서버가 깊이를 계산해 3단계에서 막는다.
  Future<void> addComment(
    String targetUserId,
    String body, {
    String? parentId,
    String? imageKey,
  }) => _client.post(
    '/posts/$targetUserId/comments',
    body: {
      'body': body,
      'parentId': ?parentId,
      'imageKey': ?imageKey,
    },
  );

  /// 댓글 첨부 이미지 업로드: URL 발급 → 바이트 직접 전송 → **키를 돌려준다**.
  /// 키는 댓글을 등록할 때 함께 보낸다(포스트 사진과 같은 흐름).
  Future<String> uploadCommentImage({
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final issued = await _client.post(
      '/posts/comments/image:upload-url',
      query: {'contentType': contentType},
    );
    final map = Map<String, dynamic>.from(issued as Map);
    await _client.putBytes(
      map['uploadUrl'] as String,
      bytes: bytes,
      contentType: contentType,
    );
    return map['storageKey'] as String;
  }

  // ── 무료 번역 자리 (⑦단계) ────────────────────────────────

  /// 댓글창을 열며 무료 자리를 하나 쓴다(기획 4-2 · 8-3 — "댓글창 5회 호출까지 무료").
  Future<TranslateAccess> openCommentSheetTranslate() async {
    final data = await _client.post('/translate/comment-sheet');
    return TranslateAccess.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// 자리를 쓰지 않고 상태만 본다 — 버튼 문구를 그릴 때.
  Future<TranslateAccess> peekCommentSheetTranslate() async {
    final data = await _client.get('/translate/comment-sheet');
    return TranslateAccess.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// 대화방에 들어가며 자리를 잡는다(기획 5장 — "대화방 5개까지, 삭제 전까지 계속").
  Future<TranslateAccess> openRoomTranslate(String roomId) async {
    final data = await _client.post('/translate/rooms/$roomId');
    return TranslateAccess.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
