// 채팅 DTO. (docs/01-protocol-api-spec.md §1.5~1.6)

import '../../../../core/util/server_time.dart';

class ChatRoomSummary {
  const ChatRoomSummary({
    required this.roomId,
    required this.type,
    required this.partnerId,
    required this.partnerNickname,
    required this.unreadCount,
    this.partnerAge,
    this.partnerCountry,
    this.partnerPhotoUrl,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String roomId;

  /// MATCH(매칭 대화) | FRIEND(친구 상시)
  final String type;

  final String partnerId;
  final String partnerNickname;
  final int? partnerAge;
  final String? partnerCountry;
  final String? partnerPhotoUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  String get flag => switch (partnerCountry) {
    'KR' => '🇰🇷',
    'JP' => '🇯🇵',
    _ => '',
  };

  factory ChatRoomSummary.fromJson(Map<String, dynamic> json) =>
      ChatRoomSummary(
        roomId: json['roomId'] as String,
        type: json['type'] as String? ?? 'MATCH',
        partnerId: json['partnerId'] as String? ?? '',
        partnerNickname: json['partnerNickname'] as String? ?? '',
        partnerAge: json['partnerAge'] as int?,
        partnerCountry: json['partnerCountry'] as String?,
        partnerPhotoUrl: json['partnerPhotoUrl'] as String?,
        lastMessage: json['lastMessage'] as String?,
        lastMessageAt: json['lastMessageAt'] == null
            ? null
            : parseServerTime(json['lastMessageAt']),
        unreadCount: json['unreadCount'] as int? ?? 0,
      );
}

/// 대화 신청(받은/보낸 공용).
class ChatRequest {
  const ChatRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.message,
    required this.status,
    required this.partnerNickname,
    this.partnerAge,
    this.partnerCountry,
    this.partnerPhotoUrl,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String message;

  /// PENDING | ACCEPTED | REJECTED | BLOCKED
  final String status;

  final String partnerNickname;
  final int? partnerAge;
  final String? partnerCountry;
  final String? partnerPhotoUrl;

  /// 보낸 신청 목록의 상태 문구(기획서 5장).
  String get sentStatusLabel =>
      status == 'PENDING' ? '대화 대기 중' : '대화 종료';

  factory ChatRequest.fromJson(Map<String, dynamic> json) => ChatRequest(
    id: json['id'] as String,
    fromUserId: json['fromUserId'] as String? ?? '',
    toUserId: json['toUserId'] as String? ?? '',
    message: json['message'] as String? ?? '',
    status: json['status'] as String? ?? 'PENDING',
    partnerNickname: json['partnerNickname'] as String? ?? '',
    partnerAge: json['partnerAge'] as int?,
    partnerCountry: json['partnerCountry'] as String?,
    partnerPhotoUrl: json['partnerPhotoUrl'] as String?,
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final bool read;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] ?? json['messageId']) as String,
    roomId: json['roomId'] as String? ?? '',
    senderId: json['senderId'] as String? ?? '',
    body: json['body'] as String? ?? '',
    createdAt: parseServerTimeOr(json['createdAt']),
    read: json['read'] as bool? ?? false,
  );
}
