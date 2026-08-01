import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../data/models/feed_item.dart';
import '../providers/garden_provider.dart';

/// 포스트 댓글 시트(기획서 4-2). 대댓글 없음, 최대 25자.
Future<void> showCommentsSheet(BuildContext context, FeedItem item) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.panel,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _CommentsSheet(item: item),
  );
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.item});

  final FeedItem item;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref.read(gardenApiProvider).addComment(widget.item.userId, text);
      _controller.clear();
      ref.invalidate(commentsProvider(widget.item.userId));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.item.userId));

    return Padding(
      // 키보드가 올라와도 입력창이 가려지지 않도록.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.pagePad),
              child: Row(
                children: [
                  Text(
                    '${widget.item.nickname}님의 포스트',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '댓글',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: comments.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.moonlight),
                ),
                error: (error, _) => const Center(
                  child: Text(
                    '댓글을 불러오지 못했어요.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                data: (list) => list.isEmpty
                    ? const Center(
                        child: Text(
                          '첫 댓글을 남겨보세요.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.pagePad,
                        ),
                        itemCount: list.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppDimens.gapMd),
                        itemBuilder: (context, i) {
                          final c = list[i];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.authorNickname,
                                style: const TextStyle(
                                  color: AppColors.moonlight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.body,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.pagePad),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: 25,
                      cursorColor: AppColors.moonlight,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '댓글을 남겨보세요 (최대 25자)',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMd,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send, color: AppColors.moonlight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
