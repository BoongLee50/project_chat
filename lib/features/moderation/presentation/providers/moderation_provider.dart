import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../friend/presentation/providers/friend_provider.dart';

/// 신고·차단 — 성공하면 null, 실패하면 사용자에게 보여줄 메시지.
///
/// 둘 다 서버에서 **친구 관계를 끊고 대화방을 종료**시키므로(02 §1.6),
/// 성공 후에는 대화방·친구 목록을 다시 읽어 화면을 맞춘다.
class ModerationActions {
  const ModerationActions(this._ref);

  final Ref _ref;

  Future<String?> report({
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

  Future<String?> block(String targetUserId) =>
      _run(() => _ref.read(moderationApiProvider).block(targetUserId));

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      await _ref.read(chatRoomsProvider.notifier).refresh();
      await _ref.read(friendsProvider.notifier).refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final moderationActionsProvider =
    Provider<ModerationActions>(ModerationActions.new);
