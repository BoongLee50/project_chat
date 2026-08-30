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
import '../../../postinfo/presentation/screens/profile_view_screen.dart';
import '../../../store/data/models/store_models.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../../../store/presentation/screens/pass_screen.dart';
import '../../data/models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/voice_player.dart';
import '../providers/voice_recorder.dart';
import '../widgets/voice_message.dart';
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

  /// 음성 전송 중. 올리기 버튼을 두 번 눌러 같은 녹음이 두 번 가는 걸 막는다.
  bool _sendingVoice = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 마이크 버튼 — 녹음 시작. 권한이 없으면 안내만 하고 아무것도 바꾸지 않는다.
  Future<void> _startRecording() async {
    // 듣고 있던 게 있으면 멈춘다. 녹음과 재생이 겹치면 마이크에 그 소리가 섞인다.
    await ref.read(voicePlayerProvider.notifier).stop();
    final ok = await ref.read(voiceRecorderProvider.notifier).start();
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(L10n.of(context).voicePermissionDenied)),
      );
  }

  /// 올리기 버튼 — 녹음 파일을 올리고 메시지로 보낸다.
  Future<void> _sendVoice() async {
    final myId = ref.read(sessionProvider).profile?.id;
    if (myId == null) return;

    final recorder = ref.read(voiceRecorderProvider.notifier);
    final take = ref.read(voiceRecorderProvider);
    final bytes = await recorder.readBytes();
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      // 파일이 사라졌거나 길이가 0. 남은 상태만 정리하고 끝낸다.
      await recorder.discard();
      return;
    }

    setState(() => _sendingVoice = true);
    // 재생 중이던 미리듣기를 멈춰야 보낸 뒤 상태가 깨끗해진다.
    await ref.read(voicePlayerProvider.notifier).stop();
    final error = await ref
        .read(chatMessagesProvider(widget.room.roomId).notifier)
        .sendVoice(
          bytes: bytes,
          durationMs: take.elapsed.inMilliseconds,
          myUserId: myId,
        );
    if (!mounted) return;
    setState(() => _sendingVoice = false);

    if (error != null) {
      // 실패해도 녹음은 남겨 둔다 — 다시 누르면 그대로 재전송할 수 있다.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(errorMessage(L10n.of(context), error))),
        );
      return;
    }
    await recorder.discard();
    if (!mounted) return;
    _scrollToBottom();
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
                    // 날짜가 바뀌는 자리마다 구분선을 넣는다(시안의 `오늘`).
                    // 없으면 어제 밤 대화와 오늘 대화가 한 덩어리로 붙어 보인다.
                    for (var i = 0; i < list.length; i++) ...[
                      if (_startsNewDay(list, i))
                        _DateDivider(date: list[i].createdAt),
                      _Bubble(
                        message: list[i],
                        mine: list[i].senderId == myId,
                        avatarUrl: widget.room.partnerPhotoUrl,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // 녹음 중이거나 녹음본이 손에 있으면 입력창 대신 녹음 바를 보여준다.
            if (ref.watch(voiceRecorderProvider).phase != VoiceRecordPhase.idle)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: VoiceRecordBar(
                  onSend: _sendVoice,
                  busy: _sendingVoice,
                ),
              )
            else
              _InputBar(
                controller: _controller,
                onSend: _send,
                onRecord: _startRecording,
              ),
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
          // 시안(5장)은 **한 줄**이다 — `지우 28 🇰🇷`. 나이를 아래로 내리면
          // 두 줄이 되어 번역 칩이 들어갈 자리가 사라진다.
          Flexible(
            child: Text(
              room.partnerAge == null
                  ? room.partnerNickname
                  : '${room.partnerNickname} ${room.partnerAge}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (room.flag.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(room.flag, style: const TextStyle(fontSize: 14)),
          ],
          const SizedBox(width: 8),
          const _TranslatePassChip(),
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
            // 지금까지 이 항목은 **눌러도 아무 일도 하지 않았다**(핸들러 누락).
            if (value == 'profile') showProfileView(context, room.partnerId);
          },
          // 순서도 시안(img11)을 따른다 — 보기 → 신고 → 차단 → 친구 → 나가기.
          itemBuilder: (context) => [
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
            // 이미 친구인 방(FRIEND)에서는 요청 항목을 숨긴다.
            if (room.type != 'FRIEND')
              PopupMenuItem(
                value: 'friend',
                child: _MenuRow(Icons.person_add_alt, l10n.chatMenuFriendRequest),
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

/// 앞 메시지와 **날짜가 다른가**. 첫 메시지는 언제나 새 날이다.
bool _startsNewDay(List<ChatMessage> list, int i) {
  if (i == 0) return true;
  final a = list[i - 1].createdAt;
  final b = list[i].createdAt;
  return a.year != b.year || a.month != b.month || a.day != b.day;
}

/// `오늘` / `어제` / `2026. 08. 28.` 구분선(시안 5장).
class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final today = DateTime.now();
    final days = DateTime(today.year, today.month, today.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;

    final label = switch (days) {
      0 => l10n.chatDateToday,
      1 => l10n.chatDateYesterday,
      _ => '${date.year}. ${date.month.toString().padLeft(2, '0')}. '
          '${date.day.toString().padLeft(2, '0')}.',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapMd),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// 상단 바의 `[⭐ 번역 | 4일]` 칩(기획 5장 img11).
///
/// **패스를 가지고 있으면 남은 일수**, 없으면 `구매`. 누르면 자동 번역 패스 화면으로 간다.
///
/// 📌 여기는 **상태를 보여 주고 사는 자리**일 뿐, 메시지를 실제로 번역하는 버튼은 아니다.
/// 번역 공급자가 아직 패스스루라 지금 번역을 붙이면 "번역했는데 원문 그대로"가 된다 —
/// 그 작업은 ⑦단계다(docs/09).
class _TranslatePassChip extends ConsumerWidget {
  const _TranslatePassChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;

    // 프라임은 번역이 무제한이라 남은 날짜라는 개념이 없다.
    final days = wallet.prime
        ? null
        : wallet.remainingDays(StoreKind.translatePass);
    final owned = wallet.prime || (days != null && days > 0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context)
          .push(PassScreen.route(StoreKind.translatePass)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: owned ? AppColors.gold : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 13,
              color: owned ? AppColors.gold : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.chatTranslatePass,
              style: TextStyle(
                color: owned ? AppColors.gold : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            Container(width: 1, height: 10, color: AppColors.border),
            const SizedBox(width: 5),
            Text(
              wallet.prime
                  ? l10n.chatTranslateUnlimited
                  : (days != null && days > 0
                        ? l10n.homePassRemainingDays(days)
                        : l10n.homeBuy),
              style: TextStyle(
                color: owned ? AppColors.gold : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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
          // 시안은 자물쇠가 아니라 **달**이다 — 보안 안내가 아니라 매칭 인사다.
          const Icon(
            Icons.nightlight_round,
            color: AppColors.moonlight,
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
                  child: message.isVoice
                      ? VoiceBubbleContent(
                          message: message,
                          foreground: mine
                              ? const Color(0xFF20202A)
                              : const Color(0xFF2A2620),
                        )
                      : Text(
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
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onRecord,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onRecord;

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
          const SizedBox(width: 8),
          // 마이크 — 누르면 녹음이 시작되고 이 줄이 녹음 바로 바뀐다.
          Material(
            color: AppColors.surfaceHigh,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRecord,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.mic_none, color: AppColors.moonlight, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
