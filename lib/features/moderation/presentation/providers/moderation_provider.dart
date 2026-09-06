import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../friend/presentation/providers/friend_provider.dart';

/// 신고·차단 — 성공하면 null, 실패하면 사용자에게 보여줄 메시지.
///
/// 둘 다 서버에서 **대기 중인 대화 신청을 닫고, 친구 관계를 끊고, 대화방을 종료**시키므로
/// (02 §1.6), 성공 후에는 그 셋을 모두 다시 읽어 화면을 맞춘다.
///
/// 🚨 **받은 신청을 빠뜨리면 차단한 사람의 카드가 화면에 남는다.** 서버에서 지워졌는데
/// 목록만 낡은 상태라, 눌러도 열리지 않는 카드가 된다.
class ModerationActions {
  const ModerationActions(this._ref);

  final Ref _ref;

  Future<ApiException?> report({
    required String targetUserId,
    required String reason,
    String? detail,
  }) => _run(
    () => _ref.read(moderationApiProvider).report(
      targetUserId: targetUserId,
      reason: reason,
      detail: detail,
    ),
  );

  Future<ApiException?> block(String targetUserId) =>
      _run(() => _ref.read(moderationApiProvider).block(targetUserId));

  Future<ApiException?> _run(Future<void> Function() action) async {
    try {
      await action();
      await _ref.read(chatRoomsProvider.notifier).refresh();
      await _ref.read(friendsProvider.notifier).refresh();
      _ref.invalidate(receivedRequestsProvider);
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }
}

final moderationActionsProvider =
    Provider<ModerationActions>(ModerationActions.new);
