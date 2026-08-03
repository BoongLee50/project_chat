import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../../moderation/presentation/widgets/block_dialog.dart';
import '../../../moderation/presentation/widgets/report_dialog.dart';
import '../../data/models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// 채팅창 — 대화방에서 항목을 선택하면 열린다. (기획서 5-1)
///
/// 히스토리는 REST로 읽고, 이후 메시지는 WebSocket으로 실시간 송수신한다.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.room});

  final ChatRoomSummary room;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final myId = ref.read(sessionProvider).profile?.id;
    if (myId == null) return;

    _controller.clear();
    final error = await ref
        .read(chatMessagesProvider(widget.room.roomId).notifier)
        .send(text, myId);
    if (!mounted) return;
    if (error != null) {
      _controller.text = text; // 사라지지 않게 입력칸에 되돌려 준다
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(L10n.of(context), error))));
      return;
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  /// 친구 요청 — 상대가 수락하면 상시 대화방이 되어 운영시간 밖에도 대화가 이어진다.
  Future<void> _requestFriend() async {
    final l10n = L10n.of(context);
    final error = await ref
        .read(friendActionsProvider)
        .request(widget.room.partnerId);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error == null ? l10n.chatFriendRequestSent : errorMessage(l10n, error),
          ),
        ),
      );
  }

  /// 신고·차단은 서버가 대화방을 종료시키므로, 성공하면 화면을 닫고 목록으로 돌아간다.
  Future<void> _report() async {
    final l10n = L10n.of(context);
    final done = await ReportDialog.show(
      context,
      targetUserId: widget.room.partnerId,
      targetNickname: widget.room.partnerNickname,
    );
    if (done != true || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.chatReportDone)));
    Navigator.of(context).pop();
  }

  Future<void> _block() async {
    final l10n = L10n.of(context);
    final done = await BlockDialog.show(
      context,
      targetUserId: widget.room.partnerId,
      targetNickname: widget.room.partnerNickname,
    );
    if (done != true || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.chatBlockDone(widget.room.partnerNickname))),
      );
    Navigator.of(context).pop();
  }

  Future<void> _leave() async {
    final error = await ref
        .read(chatActionsProvider)
        .leave(widget.room.roomId);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(L10n.of(context), error))));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final messages = ref.watch(chatMessagesProvider(widget.room.roomId));
    final myId = ref.watch(sessionProvider).profile?.id;

    // 새 메시지가 오면 아래로 스크롤.
    ref.listen(chatMessagesProvider(widget.room.roomId), (_, _) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: _ChatAppBar(
        room: widget.room,
        onLeave: _leave,
        onRequestFriend: _requestFriend,
        onReport: _report,
        onBlock: _block,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: messages.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.moonlight),
                ),
                error: (error, _) => Center(
                  child: Text(
                    l10n.chatLoadFailed,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
                data: (list) => ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppDimens.pagePad),
                  children: [
                    _SystemMessage(l10n.chatMatchedNotice),
                    const SizedBox(height: AppDimens.gapMd),
                    for (final message in list)
                      _Bubble(
                        message: message,
                        mine: message.senderId == myId,
                        avatarUrl: widget.room.partnerPhotoUrl,
                      ),
                  ],
                ),
              ),
            ),
            _InputBar(controller: _controller, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.room,
    required this.onLeave,
    required this.onRequestFriend,
    required this.onReport,
    required this.onBlock,
  });

  final ChatRoomSummary room;
  final VoidCallback onLeave;
  final VoidCallback onRequestFriend;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return AppBar(
      backgroundColor: AppColors.night,
      titleSpacing: 0,
      leadingWidth: 40,
      title: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: room.partnerPhotoUrl == null
                  ? const ColoredBox(
                      color: AppColors.surfaceHigh,
                      child: Icon(
                        Icons.person,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    )
                  : AuthedImage(url: room.partnerPhotoUrl!),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    room.partnerNickname,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(room.flag, style: const TextStyle(fontSize: 14)),
                ],
              ),
              if (room.partnerAge != null)
                Text(
                  l10n.ageYears(room.partnerAge!),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
          color: AppColors.surfaceHigh,
          onSelected: (value) {
            if (value == 'leave') onLeave();
            if (value == 'friend') onRequestFriend();
            if (value == 'report') onReport();
            if (value == 'block') onBlock();
          },
          itemBuilder: (context) => [
            // 이미 친구인 방(FRIEND)에서는 요청 항목을 숨긴다.
            if (room.type != 'FRIEND')
              PopupMenuItem(
                value: 'friend',
                child: _MenuRow(Icons.person_add_alt, l10n.chatMenuFriendRequest),
              ),
            PopupMenuItem(
              value: 'profile',
              child: _MenuRow(Icons.person_outline, l10n.chatMenuProfile),
            ),
            PopupMenuItem(
              value: 'report',
              child: _MenuRow(Icons.flag_outlined, l10n.chatMenuReport),
            ),
            PopupMenuItem(
              value: 'block',
              child: _MenuRow(Icons.block, l10n.chatMenuBlock),
            ),
            PopupMenuItem(
              value: 'leave',
              child: _MenuRow(Icons.logout, l10n.chatMenuLeave),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
      ],
    );
  }
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    this.avatarUrl,
  });

  final ChatMessage message;
  final bool mine;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.createdAt).format(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapMd),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine) ...[
            ClipOval(
              child: SizedBox(
                width: 36,
                height: 36,
                child: avatarUrl == null
                    ? const ColoredBox(
                        color: AppColors.surfaceHigh,
                        child: Icon(
                          Icons.person,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                      )
                    : AuthedImage(url: avatarUrl!),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: mine
                        ? const Color(0xFFF4F4F6)
                        : const Color(0xFFF2EAD8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(mine ? 18 : 4),
                      topRight: Radius.circular(mine ? 4 : 18),
                      bottomLeft: const Radius.circular(18),
                      bottomRight: const Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    message.body,
                    style: TextStyle(
                      color: mine
                          ? const Color(0xFF20202A)
                          : const Color(0xFF2A2620),
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        color: message.read
                            ? AppColors.moonlight
                            : AppColors.textMuted,
                        size: 15,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (mine) const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: AppColors.moonlight,
              style: const TextStyle(color: AppColors.textPrimary),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: l10n.chatInputHint,
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.moonlight,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
