import 'dart:convert';

/// 소켓 공통 봉투 `{op, seq, ts, data}` (docs/01 §2.1).
class Packet {
  const Packet({required this.op, this.seq, this.ts, this.data = const {}});

  final String op;

  /// 클라 시퀀스 — 전송 ACK 매칭/중복 방지에 사용.
  final int? seq;

  final int? ts;
  final Map<String, dynamic> data;

  String encode() => jsonEncode({
    'op': op,
    if (seq != null) 'seq': seq,
    'ts': ts ?? DateTime.now().millisecondsSinceEpoch,
    'data': data,
  });

  factory Packet.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return Packet(
      op: json['op'] as String? ?? '',
      seq: json['seq'] as int?,
      ts: json['ts'] as int?,
      data: json['data'] == null
          ? const {}
          : Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}

/// 소켓 opcode (docs/01 §2.2). 서버 Opcodes.java와 1:1 대응.
abstract final class Op {
  // C → S
  static const auth = 'AUTH';
  static const ping = 'PING';
  static const roomSubscribe = 'ROOM_SUBSCRIBE';
  static const chatSend = 'CHAT_SEND';
  static const chatRead = 'CHAT_READ';

  // S → C
  static const authOk = 'AUTH_OK';
  static const authFail = 'AUTH_FAIL';
  static const pong = 'PONG';
  static const chatSentAck = 'CHAT_SENT_ACK';
  static const chatRecv = 'CHAT_RECV';
  static const chatReadReceipt = 'CHAT_READ_RECEIPT';
  static const chatReqIncoming = 'CHAT_REQ_INCOMING';
  static const roomState = 'ROOM_STATE';
  static const presenceUpdate = 'PRESENCE_UPDATE';
  static const unreadCount = 'UNREAD_COUNT';
  static const systemClose = 'SYSTEM_CLOSE';
  static const error = 'ERROR';
}
