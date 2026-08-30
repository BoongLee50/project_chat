import 'dart:ui';

import '../../../../core/network/dio_client.dart';
import '../../../garden/data/models/feed_item.dart' show Comment;
import '../models/daily_models.dart';

/// 달빛 한마디 REST 호출. (docs/01 §1.9)
class DailyApi {
  const DailyApi(this._client);

  final DioClient _client;

  /// 질문 본문은 **콘텐츠**라 ARB에 없다 — 기기 언어를 보내 서버가 골라 준다.
  String get _lang => PlatformDispatcher.instance.locale.languageCode == 'ja'
      ? 'ja'
      : 'ko';

  Future<DailyToday> today() async {
    final data = await _client.get('/daily-question/today', query: {'lang': _lang});
    return DailyToday.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<DailyAnswer>> answers({
    DailySort sort = DailySort.latest,
    int page = 0,
  }) async {
    final data = await _client.get(
      '/daily-question/answers',
      query: {'sort': sort == DailySort.popular ? 'POPULAR' : 'LATEST', 'page': page},
    );
    return (data as List)
        .map((e) => DailyAnswer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<DailyAnswer> answer(String answerId) async {
    final data = await _client.get('/daily-question/answers/$answerId');
    return DailyAnswer.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// 내 한마디. 아직 안 썼으면 `DAILY_ANSWER_NOT_YET`(404)이 온다.
  Future<DailyAnswer> myAnswer() async {
    final data = await _client.get('/daily-question/answers/me');
    return DailyAnswer.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<DailyAnswer> write({required String body, String? imageKey}) async {
    final data = await _client.post(
      '/daily-question/answers',
      body: {'body': body, 'imageKey': ?imageKey},
    );
    return DailyAnswer.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ── 댓글은 포스트와 같은 규칙(3단계·50자·이미지 1장)이라 화면도 공유한다 ──

  Future<List<Comment>> comments(String answerId) async {
    final data = await _client.get('/daily-question/answers/$answerId/comments');
    return (data as List)
        .map((e) => Comment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> addComment(
    String answerId,
    String body, {
    String? parentId,
    String? imageKey,
  }) => _client.post(
    '/daily-question/answers/$answerId/comments',
    body: {'body': body, 'parentId': ?parentId, 'imageKey': ?imageKey},
  );

  Future<void> like(String answerId) =>
      _client.post('/daily-question/answers/$answerId/like');

  /// 메인 이미지 업로드: URL 발급 → 바이트 전송 → **키를 돌려준다**(포스트 사진과 같은 흐름).
  Future<String> uploadImage({
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final issued = await _client.post(
      '/daily-question/answers/image:upload-url',
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
}
