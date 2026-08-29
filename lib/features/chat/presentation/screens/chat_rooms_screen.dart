import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../data/models/chat_models.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import '../../../../l10n/app_localizations.dart';

/// 대화방 — 메인 셸의 l10n.chatRoomsTitle 탭 본문. (기획서 5장)
///
/// [매칭 대화] 진행 중인 방 + 받은 신청 / [보낸 신청] 목록을 전환해 보여준다.
/// 새 메시지·신청·방 상태 변화는 소켓 이벤트로 자동 갱신된다.
class ChatRoomsScreen extends ConsumerStatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  ConsumerState<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends ConsumerState<ChatRoomsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final rooms = ref.watch(chatRoomsProvider);
    final received = ref.watch(receivedRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.pagePad,
            AppDimens.gapMd,
            AppDimens.pagePad,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.chatRoomsTitle,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  _Dot(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.chatRoomsSubtitle,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppDimens.gapMd),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.moonlight,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await ref.read(chatRoomsProvider.notifier).refresh();
              ref.invalidate(receivedRequestsProvider);
            },
            // Plan_3은 [대화]와 [받은 신청]을 탭으로 나누지만, 그 분리는 ⑥단계(포스트 정보 화면)와
            // 함께 간다. 여기서는 [보낸 신청] 탭만 걷어내고 한 목록으로 둔다.
            child: _MatchedList(rooms: rooms, received: received),
          ),
        ),
      ],
    );
  }
}

/// 매칭 대화 + 받은 신청.
class _MatchedList extends ConsumerWidget {
  const _MatchedList({required this.rooms, required this.received});

  final AsyncValue<List<ChatRoomSummary>> rooms;
  final AsyncValue<List<ChatRequest>> received;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final roomList = rooms.valueOrNull ?? const <ChatRoomSummary>[];
    final requestList = received.valueOrNull ?? const <ChatRequest>[];

    if (rooms.isLoading && roomList.isEmpty) {
      return const _Loading();
    }
    if (roomList.isEmpty && requestList.isEmpty) {
      return _Empty(l10n.chatRoomsEmpty);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePad,
        0,
        AppDimens.pagePad,
        AppDimens.gapMd,
      ),
      children: [
        if (requestList.isNotEmpty) ...[
          _SectionLabel(l10n.chatTabReceived),
          for (final request in requestList)
            _RequestTile(request: request),
          const SizedBox(height: AppDimens.gapMd),
          _SectionLabel(l10n.chatRoomsOngoing),
        ],
        for (final room in roomList) _RoomTile(room: room),
      ],
    );
  }
}

class _RequestTile extends ConsumerWidget {
  const _RequestTile({required this.request});

  final ChatRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    Future<void> run(Future<ApiException?> Function() action) async {
      final error = await action();
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(errorMessage(l10n, error))));
      }
    }

    final actions = ref.read(chatActionsProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapSm),
      child: _Card(
        child: Column(
          children: [
            Row(
              children: [
                _Avatar(url: request.partnerPhotoUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameAge(request.partnerNickname, request.partnerAge),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        request.message,
                        maxLines: 2,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.gapMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => run(() => actions.reject(request.id)),
                    child: Text(l10n.commonReject),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => run(() => actions.accept(request.id)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.moonlight,
                    ),
                    child: Text(l10n.commonAccept),
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

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});

  final ChatRoomSummary room;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapSm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatScreen(room: room)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _Avatar(url: room.partnerPhotoUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _nameAge(room.partnerNickname, room.partnerAge),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            room.flag,
                            style: const TextStyle(fontSize: 15),
                          ),
                          // 친구 상시 대화방은 운영시간과 무관하게 유지되므로 구분해 준다.
                          if (room.type == 'FRIEND') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.moonlight.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.chatTabFriend,
                                style: TextStyle(
                                  color: AppColors.moonlight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(l10n, room.lastMessageAt),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        // 목록 미리보기는 25자까지만(기획서 5장)
                        _preview(l10n, room.lastMessageType, room.lastMessage),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (room.unreadCount > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.moonlight,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'N',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _preview(L10n l10n, ChatMessageType type, String? text) {
    // 음성 메시지는 본문이 없다. 빈 문자열을 그대로 두면 "대화를 시작해보세요"로
    // 보여서 방금 보낸 게 사라진 것처럼 느껴진다.
    if (type == ChatMessageType.voice) return l10n.chatRoomsVoicePreview;
    if (text == null || text.isEmpty) return l10n.chatRoomsStart;
    final chars = text.characters;
    return chars.length <= 25 ? text : '${chars.take(25)}…';
  }

  static String _timeAgo(L10n l10n, DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    return l10n.timeDaysAgo(diff.inDays);
  }
}

String _nameAge(String name, int? age) =>
    age == null ? name : '$name $age';

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 60,
        height: 60,
        child: url == null
            ? const ColoredBox(
                color: AppColors.surfaceHigh,
                child: Icon(Icons.person, color: AppColors.textMuted),
              )
            : AuthedImage(url: url!),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapSm),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.moonlight),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(
          Icons.forum_outlined,
          color: AppColors.textMuted,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.moonlight,
        shape: BoxShape.circle,
      ),
    );
  }
}
