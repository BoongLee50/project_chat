import '../../../../core/network/dio_client.dart';
import '../models/chat_models.dart';

/// 대화 신청·대화방 REST 호출. (docs/01 §1.5~1.6)
class ChatApi {
  const ChatApi(this._client);

  final DioClient _client;

  /// 대화 신청 — 하루 무료 2회 후 루나 5 차감(서버 판정).
  Future<void> createRequest({
    required String targetUserId,
    required String message,
  }) => _client.post(
    '/chat-requests',
    body: {'targetUserId': targetUserId, 'message': message},
  );

  Future<List<ChatRoomSummary>> rooms() async {
    final data = await _client.get('/chat/rooms');
    return (data as List)
        .map((e) => ChatRoomSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<ChatRequest>> receivedRequests() async {
    final data = await _client.get('/chat/rooms/received');
    return (data as List)
        .map((e) => ChatRequest.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }


  /// 메시지 히스토리(오래된 → 최신 순으로 내려옴).
  Future<List<ChatMessage>> messages(String roomId, {String? cursor}) async {
    final data = await _client.get(
      '/chat/rooms/$roomId/messages',
      query: {'cursor': ?cursor},
    );
    final map = Map<String, dynamic>.from(data as Map);
    return (map['items'] as List? ?? const [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<String> accept(String requestId) async {
    final data = await _client.post('/chat/requests/$requestId:accept');
    return (data as Map)['roomId'] as String;
  }

  Future<void> reject(String requestId) =>
      _client.post('/chat/requests/$requestId:reject');

  Future<void> leave(String roomId) => _client.post('/chat/rooms/$roomId:leave');

  /// 음성 파일 업로드 → 스토리지 key 반환.
  ///
  /// 여기서는 파일만 올린다. 메시지는 이 key를 소켓으로 보내야 만들어진다 —
  /// 올려 두고 보내지 않으면 파일만 남고 대화에는 안 나타난다.
  Future<String> uploadVoice({
    required String roomId,
    required List<int> bytes,
    String contentType = 'audio/mp4',
  }) async {
    final issued = await _client.post(
      '/chat/rooms/$roomId/voice:upload-url',
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
