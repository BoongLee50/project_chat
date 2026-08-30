import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/packet.dart';
import '../../../../core/providers.dart';
import '../../../../core/util/server_time.dart';
import '../../data/models/chat_models.dart';

/// 대화방 목록(매칭 대화). 소켓 이벤트가 오면 자동 갱신된다.
class ChatRoomsController extends AsyncNotifier<List<ChatRoomSummary>> {
  @override
  Future<List<ChatRoomSummary>> build() async {
    // 방 상태 변화·새 메시지·미확인 수 변경 시 목록을 다시 읽는다.
    final sub = ref.listen(socketPacketProvider, (previous, next) {
      final op = next.valueOrNull?.op;
      if (op == Op.chatRecv ||
          op == Op.roomState ||
          op == Op.unreadCount ||
          op == Op.chatReqIncoming ||
          op == Op.friendState || // 친구 수락 → 상시 대화방 생성/삭제
          op == Op.authOk) {
        // AUTH_OK = 재연결 직후. 끊겨 있던 동안 놓친 변화를 여기서 따라잡는다.
        refresh();
      }
    });
    ref.onDispose(sub.close);

    return ref.read(chatApiProvider).rooms();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(chatApiProvider).rooms());
  }
}

final chatRoomsProvider =
    AsyncNotifierProvider<ChatRoomsController, List<ChatRoomSummary>>(
      ChatRoomsController.new,
    );

/// 내가 받은 대화 신청(대기 중). 새 신청이 소켓으로 오면 자동 갱신된다.
final receivedRequestsProvider = FutureProvider<List<ChatRequest>>((ref) {
  ref.listen(socketPacketProvider, (previous, next) {
    final op = next.valueOrNull?.op;
    if (op == Op.chatReqIncoming || op == Op.roomState) {
      ref.invalidateSelf();
    }
  });
  return ref.read(chatApiProvider).receivedRequests();
});

/// 채팅방 하나의 메시지 목록 — 히스토리(REST) + 실시간 수신(소켓)을 합친다.
class ChatMessagesController
    extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  @override
  Future<List<ChatMessage>> build(String roomId) async {
    final socket = ref.read(socketClientProvider);

    // 방 구독(서버가 읽음 처리도 함께 수행).
    socket.send(Op.roomSubscribe, {'roomId': roomId});

    final sub = ref.listen(socketPacketProvider, (previous, next) {
      final packet = next.valueOrNull;
      if (packet == null) return;
      if (packet.op == Op.chatRecv && packet.data['roomId'] == roomId) {
        _append(ChatMessage.fromJson(packet.data));
        // 화면을 보고 있으므로 즉시 읽음 처리.
        socket.send(Op.chatRead, {'roomId': roomId});
      } else if (packet.op == Op.authOk) {
        // 재연결됨 — 구독을 되살리고 끊긴 사이 온 메시지를 다시 읽어온다.
        socket.send(Op.roomSubscribe, {'roomId': roomId});
        ref.invalidateSelf();
      }
    });
    ref.onDispose(sub.close);

    return ref.read(chatApiProvider).messages(roomId);
  }

  void _append(ChatMessage message) {
    final current = state.valueOrNull ?? const <ChatMessage>[];
    if (current.any((m) => m.id == message.id)) return; // 중복 방지
    state = AsyncValue.data([...current, message]);
  }

  /// 메시지 전송 — 소켓으로 보내고, 서버의 CHAT_SENT_ACK를 받아 목록에 반영한다.
  /// 성공하면 null, 실패하면 화면이 문구로 바꿀 예외를 돌려준다.
  Future<ApiException?> send(String body, String myUserId) async {
    final text = body.trim();
    if (text.isEmpty) return null;

    final socket = ref.read(socketClientProvider);
    final seq = socket.send(Op.chatSend, {'roomId': arg, 'body': text});
    if (seq == null) {
      unawaited(socket.connect()); // 끊겨 있으면 즉시 재연결 시도
      return const ApiException(
        message: '연결이 끊겼어요. 잠시 후 다시 보내주세요.',
        code: ClientErrorCode.socketDisconnected,
      );
    }

    // ACK를 기다렸다가 서버가 확정한 id/시각으로 추가(낙관적 표시 대신 정확성 우선).
    final Packet ack;
    try {
      ack = await socket.packets
          .firstWhere((p) => p.op == Op.chatSentAck && p.seq == seq)
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      return const ApiException(
        message: '메시지를 보내지 못했어요. 다시 시도해 주세요.',
        code: ClientErrorCode.socketSendTimeout,
      );
    }
    _append(
      ChatMessage(
        id: ack.data['messageId'] as String,
        roomId: arg,
        senderId: myUserId,
        body: text,
        createdAt: parseServerTimeOr(ack.data['createdAt']),
      ),
    );
    return null;
  }

  /// 음성 메시지 전송 — 파일을 먼저 올리고, 받은 key를 소켓으로 보낸다.
  ///
  /// 업로드(REST)와 전송(소켓)이 나뉘어 있어 중간에 실패하면 파일만 남을 수 있다.
  /// 고아 파일은 메시지가 없으니 화면에 안 나오고, 보관 배치가 정리 대상으로 본다.
  Future<ApiException?> sendVoice({
    required List<int> bytes,
    required int durationMs,
    required String myUserId,
  }) async {
    final String audioKey;
    try {
      audioKey = await ref
          .read(chatApiProvider)
          .uploadVoice(roomId: arg, bytes: bytes);
    } on ApiException catch (e) {
      return e;
    }

    final socket = ref.read(socketClientProvider);
    final seq = socket.send(Op.chatSend, {
      'roomId': arg,
      'type': ChatMessageType.voice.wire,
      'audioKey': audioKey,
      'audioDurationMs': durationMs,
    });
    if (seq == null) {
      unawaited(socket.connect());
      return const ApiException(
        message: '연결이 끊겼어요. 잠시 후 다시 보내주세요.',
        code: ClientErrorCode.socketDisconnected,
      );
    }

    final Packet ack;
    try {
      ack = await socket.packets
          .firstWhere((p) => p.op == Op.chatSentAck && p.seq == seq)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      return const ApiException(
        message: '메시지를 보내지 못했어요. 다시 시도해 주세요.',
        code: ClientErrorCode.socketSendTimeout,
      );
    }
    _append(
      ChatMessage(
        id: ack.data['messageId'] as String,
        roomId: arg,
        senderId: myUserId,
        type: ChatMessageType.voice,
        body: '',
        audioUrl: ack.data['audioUrl'] as String?,
        audioDurationMs: (ack.data['audioDurationMs'] as num?)?.toInt(),
        createdAt: parseServerTimeOr(ack.data['createdAt']),
      ),
    );
    return null;
  }
}

final chatMessagesProvider =
    AsyncNotifierProvider.family<
      ChatMessagesController,
      List<ChatMessage>,
      String
    >(ChatMessagesController.new);

/// 대화 신청 보내기 / 수락 / 거절 / 나가기 — 성공하면 null, 실패하면 메시지.
class ChatActions {
  const ChatActions(this._ref);

  final Ref _ref;

  Future<ApiException?> requestChat(String targetUserId, String message) async {
    try {
      await _ref
          .read(chatApiProvider)
          .createRequest(targetUserId: targetUserId, message: message);
      // 무료 횟수가 하나 줄었다 — 다음에 팝업을 열 때 옛 숫자를 보여 주면 안 된다.
      _ref.invalidate(chatRequestQuotaProvider);
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  Future<ApiException?> accept(String requestId) async {
    try {
      await _ref.read(chatApiProvider).accept(requestId);
      _ref.invalidate(receivedRequestsProvider);
      await _ref.read(chatRoomsProvider.notifier).refresh();
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  Future<ApiException?> reject(String requestId) async {
    try {
      await _ref.read(chatApiProvider).reject(requestId);
      _ref.invalidate(receivedRequestsProvider);
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  Future<ApiException?> leave(String roomId) async {
    try {
      await _ref.read(chatApiProvider).leave(roomId);
      await _ref.read(chatRoomsProvider.notifier).refresh();
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }
}

final chatActionsProvider = Provider<ChatActions>(ChatActions.new);

/// 대화 신청 안내(남은 무료 횟수·루나·글자 수).
///
/// 신청을 보내면 남은 횟수가 줄어드므로 `ChatActions.requestChat`이 무효화한다.
final chatRequestQuotaProvider = FutureProvider<ChatRequestQuota>(
  (ref) => ref.read(chatApiProvider).requestQuota(),
);
