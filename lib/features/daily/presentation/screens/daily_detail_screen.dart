import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../garden/presentation/widgets/comments_sheet.dart';
import '../providers/daily_provider.dart';

/// 달빛 한마디 [상세](기획 8-2) — 한마디 · 사진 · 좋아요 · 댓글.
///
/// **댓글은 포스트와 같은 시트를 쓴다** — 규칙이 문장까지 같다(3단계·50자·이미지 1장).
class DailyDetailScreen extends ConsumerWidget {
  const DailyDetailScreen({super.key, required this.answerId});

  final String answerId;

  static Route<void> route(String answerId) =>
      MaterialPageRoute(builder: (_) => DailyDetailScreen(answerId: answerId));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final answer = ref.watch(dailyAnswerProvider(answerId));

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.dailyTitle),
      ),
      body: answer.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (error, _) => Center(
          child: Text(
            l10n.dailyLoadFailed,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        data: (a) => ListView(
          padding: const EdgeInsets.all(AppDimens.pagePad),
          children: [
            Row(
              children: [
                Text(
                  [a.nickname, if (a.age != null) '${a.age}'].join(' '),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (a.flag.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(a.flag, style: const TextStyle(fontSize: 14)),
                ],
              ],
            ),
            const SizedBox(height: AppDimens.gapMd),
            Text(
              a.body,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            if (a.imageUrl != null) ...[
              const SizedBox(height: AppDimens.gapMd),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: AuthedImage(url: a.imageUrl!),
                ),
              ),
            ],
            const SizedBox(height: AppDimens.gapLg),
            Row(
              children: [
                GestureDetector(
                  // 사람마다 한 번이라 이미 누른 뒤에는 아무 일도 하지 않는다.
                  onTap: () async {
                    final error = await ref
                        .read(dailyListProvider.notifier)
                        .like(a);
                    ref.invalidate(dailyAnswerProvider(answerId));
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(errorMessage(L10n.of(context), error)),
                          ),
                        );
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        a.likedByMe ? Icons.favorite : Icons.favorite_border,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${a.likes}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.gapLg),
                GestureDetector(
                  onTap: () async {
                    await showCommentsSheet(
                      context,
                      kind: CommentTargetKind.dailyAnswer,
                      targetId: a.id,
                      title: a.nickname,
                    );
                    ref.invalidate(dailyAnswerProvider(answerId));
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mode_comment_outlined,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${a.comments}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
