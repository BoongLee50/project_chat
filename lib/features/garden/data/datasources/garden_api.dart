import '../../../../core/network/dio_client.dart';
import '../models/feed_item.dart';

/// 달빛가든 REST 호출. (docs/01-protocol-api-spec.md §1.4)
class GardenApi {
  const GardenApi(this._client);

  final DioClient _client;

  Future<FeedPage> feed({
    String? gender,
    int? ageDecade,
    String? country,
    String? cursor,
    bool spotlight = false,
  }) async {
    final data = await _client.get(
      spotlight ? '/feed/spotlight' : '/feed',
      query: {
        if (!spotlight && gender != null) 'gender': gender,
        if (!spotlight && ageDecade != null) 'age': ageDecade,
        if (!spotlight && country != null) 'country': country,
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

  Future<void> addComment(String targetUserId, String body) =>
      _client.post('/posts/$targetUserId/comments', body: {'body': body});
}
