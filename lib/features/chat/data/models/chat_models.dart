// 채팅 DTO. (docs/01-protocol-api-spec.md §1.5~1.6)

import '../../../../core/util/server_time.dart';
import '../../../postinfo/data/models/post_info.dart';

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
    this.lastMessageType = ChatMessageType.text,
    this.lastMessageAt,
    this.partnerOnline = false,
    this.friendRelation = FriendRelation.none,
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

  /// 마지막 메시지 종류. 음성이면 [lastMessage]가 비어 있으므로
  /// 목록 미리보기를 "음성 메시지"로 대신 그린다.
  final ChatMessageType lastMessageType;

  final DateTime? lastMessageAt;
  final int unreadCount;

  /// 🟢 접속 표시(기획 6-1).
  final bool partnerOnline;

  /// 행 오른쪽 [친구]/[친구 신청]/[신청 대기] 버튼이 보는 값.
  final FriendRelation friendRelation;

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
        lastMessageType: ChatMessageType.parse(json['lastMessageType'] as String?),
        lastMessageAt: json['lastMessageAt'] == null
            ? null
            : parseServerTime(json['lastMessageAt']),
        unreadCount: json['unreadCount'] as int? ?? 0,
        partnerOnline: json['partnerOnline'] as bool? ?? false,
        friendRelation: FriendRelation.parse(json['friendRelation'] as String?),
      );
}

/// 대화 신청을 하기 **전에** 팝업이 알아야 하는 것(기획 4-3 img09).
///
/// 시안의 버튼은 `대화 신청 (무료 2회)`처럼 남은 횟수를 적고, 안내 상자는
/// "처음 N회 무료 · 이후 M 루나 · Prime이면 무제한"을 말한다.
/// 이 값이 없으면 화면이 **숫자를 지어내게** 된다.
///
/// 🚨 이건 안내일 뿐 판정이 아니다 — 실제 차감·차단은 보낼 때 서버가 다시 본다.
class ChatRequestQuota {
  const ChatRequestQuota({
    required this.freeRemaining,
    required this.freePerDay,
    required this.lunaCost,
    required this.maxLength,
    required this.unlimited,
  });

  final int freeRemaining;
  final int freePerDay;
  final int lunaCost;
  final int maxLength;
  final bool unlimited;

  /// 지금 보내면 루나가 나가는가.
  bool get costsLuna => !unlimited && freeRemaining <= 0;

  factory ChatRequestQuota.fromJson(Map<String, dynamic> json) =>
      ChatRequestQuota(
        freeRemaining: json['freeRemaining'] as int? ?? 0,
        freePerDay: json['freePerDay'] as int? ?? 0,
        lunaCost: json['lunaCost'] as int? ?? 0,
        // 서버가 못 주면 입력칸이 아예 막히지 않도록 넉넉히 둔다 —
        // 진짜 한도는 어차피 서버가 잰다.
        maxLength: json['maxLength'] as int? ?? 200,
        unlimited: json['unlimited'] as bool? ?? false,
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
    this.partnerOnline = false,
    this.createdAt,
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

  /// 🟢 접속 표시. 받은 신청 그리드 카드에 붙는다(기획 6-1).
  final bool partnerOnline;

  /// 신청이 언제 왔는가 — 카드에 "2분 전"으로 보여 준다.
  final DateTime? createdAt;

  String get flag => switch (partnerCountry) {
    'KR' => '🇰🇷',
    'JP' => '🇯🇵',
    _ => '',
  };

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
    partnerOnline: json['partnerOnline'] as bool? ?? false,
    createdAt: json['createdAt'] == null
        ? null
        : parseServerTime(json['createdAt']),
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.type = ChatMessageType.text,
    this.audioUrl,
    this.audioDurationMs,
    this.read = false,
  });

  final String id;
  final String roomId;
  final String senderId;

  /// TEXT면 [body], VOICE면 [audioUrl]·[audioDurationMs]를 쓴다.
  final ChatMessageType type;
  final String body;

  /// 서버가 준 다운로드 경로(상대 경로). 인증이 걸려 있어 그냥 재생할 수 없고
  /// 헤더를 실어 내려받은 뒤 로컬 파일로 재생한다.
  final String? audioUrl;
  final int? audioDurationMs;

  final DateTime createdAt;
  final bool read;

  bool get isVoice => type == ChatMessageType.voice;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] ?? json['messageId']) as String,
    roomId: json['roomId'] as String? ?? '',
    senderId: json['senderId'] as String? ?? '',
    type: ChatMessageType.parse(json['type'] as String?),
    body: json['body'] as String? ?? '',
    audioUrl: json['audioUrl'] as String?,
    audioDurationMs: (json['audioDurationMs'] as num?)?.toInt(),
    createdAt: parseServerTimeOr(json['createdAt']),
    read: json['read'] as bool? ?? false,
  );
}

/// 메시지 종류. 서버가 문자열로 주므로 모르는 값은 텍스트로 떨어뜨린다 —
/// 서버에 종류가 늘어도 구버전 앱이 죽지 않게 하려는 것.
enum ChatMessageType {
  text,
  voice;

  static ChatMessageType parse(String? raw) =>
      raw == 'VOICE' ? ChatMessageType.voice : ChatMessageType.text;

  String get wire => this == ChatMessageType.voice ? 'VOICE' : 'TEXT';
}
