import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/presentation/widgets/chat_request_dialog.dart';
import '../../../postinfo/presentation/providers/post_info_provider.dart';

/// 대화 신청 한 바퀴(기획 4-3) — 팝업 → 보내기 → "보냈어요".
///
/// 가든 카드의 [대화 신청]과 **댓글의 `⋯` → [대화 신청]**(4-2)이 같은 길을 탄다.
/// 무료 횟수·루나·글자 수는 **서버가 알려 준다.** 팝업이 상대의 사진·지역·접속을 보여 주므로
/// [포스트 정보]와 같은 응답을 쓴다.
///
/// 막히면(차단·거절 1일 등) 서버 `ErrorCode` 문장을 [onError]로 돌려준다 — 띄울 자리는 부른 쪽이 안다
/// (시트 위에서 부르면 시트 안에 띄워야 보인다).
Future<void> runChatRequestFlow(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required void Function(String message) onError,
}) async {
  final l10n = L10n.of(context);
  final info = await ref.read(postInfoProvider(userId).future);
  if (!context.mounted) return;

  final message = await showChatRequestDialog(context, info: info);
  if (message == null || !context.mounted) return;

  final error = await ref
      .read(chatActionsProvider)
      .requestChat(userId, message);
  if (!context.mounted) return;
  if (error != null) {
    onError(errorMessage(l10n, error));
    return;
  }
  await showChatRequestSentDialog(context);
}
