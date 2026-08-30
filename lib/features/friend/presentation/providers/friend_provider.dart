import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/packet.dart';
import '../../../../core/providers.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../data/models/friend_models.dart';

/// 친구 목록 필터(성별·나이대·국가). 화면 상단 칩과 연결된다.
final friendFilterProvider = StateProvider<FriendFilter>(
  (ref) => const FriendFilter(),
);

/// 친구 목록(ACCEPTED). 필터 변경·친구 관계 변화·재연결 시 다시 읽는다.
class FriendsController extends AsyncNotifier<List<Friend>> {
  @override
  Future<List<Friend>> build() async {
    final filter = ref.watch(friendFilterProvider);

    final sub = ref.listen(socketPacketProvider, (previous, next) {
      final op = next.valueOrNull?.op;
      // FRIEND_STATE = 수락/거절/삭제, AUTH_OK = 재연결 직후 따라잡기.
      // PRESENCE_UPDATE는 접속 표시가 목록에 있어 함께 갱신한다.
      if (op == Op.friendState ||
          op == Op.friendReqIncoming ||
          op == Op.presenceUpdate ||
          op == Op.authOk) {
        refresh();
      }
    });
    ref.onDispose(sub.close);

    return ref.read(friendApiProvider).friends(filter);
  }

  Future<void> refresh() async {
    final filter = ref.read(friendFilterProvider);
    state = await AsyncValue.guard(
      () => ref.read(friendApiProvider).friends(filter),
    );
  }
}

final friendsProvider = AsyncNotifierProvider<FriendsController, List<Friend>>(
  FriendsController.new,
);

/// 내가 받은 친구 요청(PENDING).
final friendRequestsProvider = FutureProvider<List<FriendRequest>>((ref) {
  ref.listen(socketPacketProvider, (previous, next) {
    final op = next.valueOrNull?.op;
    if (op == Op.friendReqIncoming || op == Op.friendState || op == Op.authOk) {
      ref.invalidateSelf();
    }
  });
  return ref.read(friendApiProvider).receivedRequests();
});

/// 친구 요청/수락/거절/취소/삭제 — 성공하면 null, 실패하면 사용자에게 보여줄 메시지.
class FriendActions {
  const FriendActions(this._ref);

  final Ref _ref;

  Future<ApiException?> request(String targetUserId, {String? message}) => _run(
    () => _ref.read(friendApiProvider).request(targetUserId, message: message),
    sent: true,
  );

  Future<ApiException?> accept(String friendshipId) async {
    try {
      await _ref.read(friendApiProvider).accept(friendshipId);
      _ref.invalidate(friendRequestsProvider);
      await _ref.read(friendsProvider.notifier).refresh();
      // 상시 대화방이 생겼으니 대화방 목록도 최신화.
      await _ref.read(chatRoomsProvider.notifier).refresh();
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  Future<ApiException?> reject(String friendshipId) => _run(
    () => _ref.read(friendApiProvider).reject(friendshipId),
    received: true,
  );

  Future<ApiException?> cancel(String friendshipId) =>
      _run(() => _ref.read(friendApiProvider).cancel(friendshipId), sent: true);

  Future<ApiException?> remove(String friendshipId) async {
    try {
      await _ref.read(friendApiProvider).remove(friendshipId);
      await _ref.read(friendsProvider.notifier).refresh();
      // 상시 대화방이 닫혔으니 대화방 목록도 최신화.
      await _ref.read(chatRoomsProvider.notifier).refresh();
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  Future<ApiException?> _run(
    Future<void> Function() action, {
    bool sent = false,
    bool received = false,
  }) async {
    try {
      await action();
      if (received) _ref.invalidate(friendRequestsProvider);
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }
}

final friendActionsProvider = Provider<FriendActions>(FriendActions.new);
