import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/image_viewer.dart';
import '../../data/models/feed_item.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../providers/garden_provider.dart';

/// 댓글이 달릴 대상. 서버의 `CommentTarget`과 짝이다.
///
/// 포스트와 달빛 한마디의 댓글 규칙이 **문장까지 같아**(기획 4-2 / 8-2 / 8-3)
/// 화면도 한 벌만 둔다 — 두 벌이면 언젠가 조용히 갈라진다.
enum CommentTargetKind { post, dailyAnswer }

/// 댓글 시트. **3단계 답글** · 최대 50자 · 이미지 1장.
///
/// [title]은 시트 머리글, [targetId]는 포스트 주인의 userId(포스트) 또는 한마디 id다.
/// [ownerId]는 **글쓴이**다 — 답글 자격을 가리는 데 쓴다(아래 [_canReply]).
Future<void> showCommentsSheet(
  BuildContext context, {
  required CommentTargetKind kind,
  required String targetId,
  required String ownerId,
  required String title,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.panel,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _CommentsSheet(
      kind: kind,
      targetId: targetId,
      ownerId: ownerId,
      title: title,
    ),
  );
}

/// 포스트 카드에서 여는 지름길 — 대상이 [FeedItem] 하나로 정해져 있다.
Future<void> showPostCommentsSheet(BuildContext context, FeedItem item) =>
    showCommentsSheet(
      context,
      kind: CommentTargetKind.post,
      targetId: item.userId,
      // 포스트는 대상 id가 곧 글쓴이다.
      ownerId: item.userId,
      title: L10n.of(context).commentsTitle(item.nickname),
    );

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({
    required this.kind,
    required this.targetId,
    required this.ownerId,
    required this.title,
  });

  final CommentTargetKind kind;
  final String targetId;
  final String ownerId;
  final String title;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  /// 서버 설정(`app.comment.*`)과 같은 값. 클라는 **미리 막아 주는 역할**이고
  /// 최종 판정은 서버가 한다 — 화면만 막으면 API를 직접 부르는 것으로 뚫린다.
  static const int _maxLength = 50;
  static const int _maxDepth = 3;

  final _controller = TextEditingController();
  bool _sending = false;

  /// 답글 대상. null이면 1단계 댓글이다.
  Comment? _replyTo;

  /// 목록 프로바이더의 키. 대상 종류가 다르면 같은 id라도 다른 목록이다.
  String get _key => '${widget.kind.name}:${widget.targetId}';

  /// 이 댓글에 **내가** 답글을 달 수 있는가.
  ///
  /// 한 스레드는 **글쓴이와 그 스레드를 시작한 사람**의 1:1 대화이고 답글은 **번갈아** 달린다:
  /// `A가 글 → B가 댓글 → A가 답글 → B가 답글`. 그래서 조건은 셋이다.
  /// 1. 3단계에는 더 못 단다
  /// 2. **내 댓글에는 내가 못 단다**(자기 말에 자기가 답하면 대화가 아니다)
  /// 3. 나는 이 스레드의 두 사람 중 하나여야 한다 — 제3자는 **1단계 댓글로 새 스레드**를 연다
  ///
  /// 서버가 같은 규칙으로 다시 판정한다(`COMMENT_REPLY_NOT_ALLOWED`).
  /// 여기서 가리는 건 **버튼을 안 보이게 해서 헛걸음을 막으려는 것**이지 방어가 아니다.
  bool _canReply(Comment comment, List<Comment> all) {
    final me = ref.read(sessionProvider).profile?.id;
    if (me == null) return false;
    if (comment.depth >= _maxDepth) return false;
    if (comment.authorId == me) return false;
    return me == widget.ownerId || me == _threadStarterId(comment, all);
  }

  /// 스레드를 시작한 사람(1단계 댓글의 작성자). 깊이가 3까지라 한 번만 거슬러 올라가면 된다.
  String? _threadStarterId(Comment comment, List<Comment> all) {
    if (comment.depth == 1) return comment.authorId;
    for (final c in all) {
      if (c.id == comment.parentId) {
        return c.depth == 1 ? c.authorId : null;
      }
    }
    return null;
  }

  /// 첨부한 사진 — 올린 뒤 받은 키와, 미리보기용 바이트.
  String? _imageKey;
  List<int>? _imageBytes;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => _sending = true);
    try {
      // 등록 버튼을 누르기 전에 올려 둔다 — 전송 순간이 짧아야 답답하지 않다.
      // 이미지는 어느 쪽이든 같은 저장소(`comment-images/{userId}/`)를 쓴다.
      final key = await ref
          .read(gardenApiProvider)
          .uploadCommentImage(bytes: bytes);
      if (!mounted) return;
      setState(() {
        _imageKey = key;
        _imageBytes = bytes;
      });
    } on ApiException catch (e) {
      if (mounted) _toast(errorMessage(L10n.of(context), e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      switch (widget.kind) {
        case CommentTargetKind.post:
          await ref
              .read(gardenApiProvider)
              .addComment(
                widget.targetId,
                text,
                parentId: _replyTo?.id,
                imageKey: _imageKey,
              );
        case CommentTargetKind.dailyAnswer:
          await ref
              .read(dailyApiProvider)
              .addComment(
                widget.targetId,
                text,
                parentId: _replyTo?.id,
                imageKey: _imageKey,
              );
      }
      _controller.clear();
      setState(() {
        _replyTo = null;
        _imageKey = null;
        _imageBytes = null;
      });
      ref.invalidate(commentsProvider(_key));
    } on ApiException catch (e) {
      if (mounted) _toast(errorMessage(L10n.of(context), e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final comments = ref.watch(commentsProvider(_key));

    return Padding(
      // 키보드가 올라와도 입력창이 가려지지 않도록.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
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
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.commentsSection,
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
                error: (error, _) => Center(
                  child: Text(
                    l10n.commentsLoadFailed,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                data: (list) => list.isEmpty
                    ? Center(
                        child: Text(
                          l10n.commentsEmpty,
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
                        itemBuilder: (context, i) => _CommentTile(
                          comment: list[i],
                          canReply: _canReply(list[i], list),
                          onReply: () => setState(() => _replyTo = list[i]),
                        ),
                      ),
              ),
            ),
            if (_replyTo != null)
              _ReplyBanner(
                nickname: _replyTo!.authorNickname,
                onCancel: () => setState(() => _replyTo = null),
              ),
            if (_imageBytes != null)
              _AttachedImageBar(
                bytes: _imageBytes!,
                onRemove: () => setState(() {
                  _imageKey = null;
                  _imageBytes = null;
                }),
              ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.pagePad),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending || _imageBytes != null
                        ? null
                        : _pickImage,
                    tooltip: l10n.commentsAttachImage,
                    icon: Icon(
                      Icons.image_outlined,
                      color: _imageBytes != null
                          ? AppColors.textMuted
                          : AppColors.moonlight,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: _maxLength,
                      // 남은 글자를 보여 준다 — 50자에서 잘리는 이유가 드러나야 한다.
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => Text(
                            '$currentLength/$maxLength',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                      cursorColor: AppColors.moonlight,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.commentsHint,
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

/// 댓글 한 줄. [Comment.depth]만큼 들여쓴다 —
/// 서버가 트리 순서로 평탄화해 주므로 화면은 깊이만 보면 된다.
class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canReply,
    required this.onReply,
  });

  final Comment comment;
  final bool canReply;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Padding(
      padding: EdgeInsets.only(left: (comment.depth - 1) * 22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 답글은 한 단계 안으로 들어왔다는 걸 꺾쇠로도 알린다(들여쓰기만으로는 약하다).
              if (comment.depth > 1) ...[
                Icon(
                  Icons.subdirectory_arrow_right,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  comment.authorNickname,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.moonlight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (canReply)
                GestureDetector(
                  onTap: onReply,
                  child: Text(
                    l10n.commentsReply,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment.body,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
          if (comment.imageUrl != null) ...[
            const SizedBox(height: 8),
            // 누르면 원본만 팝업으로 띄운다(기획 4-2).
            TappableImage(url: comment.imageUrl!, width: 160, height: 120),
          ],
        ],
      ),
    );
  }

}

/// 지금 누구에게 답글을 쓰는지 알려 주는 줄. 없으면 1단계 댓글이 된다.
class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({required this.nickname, required this.onCancel});

  final String nickname;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(AppDimens.pagePad, 8, 8, 8),
      child: Row(
        children: [
          const Icon(
            Icons.subdirectory_arrow_right,
            size: 16,
            color: AppColors.moonlight,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.commentsReplyingTo(nickname),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: onCancel,
            tooltip: l10n.commentsCancelReply,
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// 첨부한 사진 미리보기(1장). 올리기는 이미 끝난 상태이고 키만 들고 있다.
class _AttachedImageBar extends StatelessWidget {
  const _AttachedImageBar({required this.bytes, required this.onRemove});

  final List<int> bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(AppDimens.pagePad, 8, 8, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              Uint8List.fromList(bytes),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.commentsImageAttached,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: l10n.commentsRemoveImage,
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
