import '../../../../core/network/dio_client.dart';
import '../models/friend_models.dart';

/// 친구 REST 호출. (docs/01 §1.7)
class FriendApi {
  const FriendApi(this._client);

  final DioClient _client;

  Future<List<Friend>> friends([FriendFilter filter = const FriendFilter()]) async {
    final data = await _client.get('/friends', query: filter.toQuery());
    return (data as List)
        .map((e) => Friend.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<FriendRequest>> receivedRequests() async {
    final data = await _client.get('/friends/requests');
    return (data as List)
        .map((e) => FriendRequest.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }


  /// [message]는 신청과 함께 보내는 한마디(선택, 25자). 길이는 서버가 잰다.
  Future<void> request(String targetUserId, {String? message}) =>
      _client.post('/friends/requests', body: {
        'targetUserId': targetUserId,
        if (message != null && message.isNotEmpty) 'message': message,
      });

  /// 수락하면 상시 대화방 id가 돌아온다.
  Future<String?> accept(String friendshipId) async {
    final data = await _client.post('/friends/requests/$friendshipId:accept');
    return (data as Map?)?['roomId'] as String?;
  }

  Future<void> reject(String friendshipId) =>
      _client.post('/friends/requests/$friendshipId:reject');

  Future<void> cancel(String friendshipId) =>
      _client.post('/friends/requests/$friendshipId:cancel');

  Future<void> remove(String friendshipId) =>
      _client.delete('/friends/$friendshipId');

  /// 친구의 오늘 포스트. 아직 공유하지 않았으면 404가 온다.
  Future<FriendPost> todayPost(String friendshipId) async {
    final data = await _client.get('/friends/$friendshipId/today-post');
    return FriendPost.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
