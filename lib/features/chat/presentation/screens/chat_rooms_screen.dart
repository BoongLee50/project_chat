import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/night_header.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../../friend/presentation/widgets/friend_request_dialog.dart';
import '../../../postinfo/presentation/providers/post_info_provider.dart';
import '../../../postinfo/data/models/post_info.dart';
import '../../../postinfo/presentation/screens/post_info_screen.dart';
import '../../data/models/chat_models.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

/// 대화방 — 메인 셸의 l10n.chatRoomsTitle 탭 본문. (기획 6-1)
///
/// 탭이 **둘**이다: `[💬 대화]`는 진행 중인 방, `[✉ 받은 신청]`은 아직 답하지 않은
/// 대화 신청. 예전에는 한 목록에 섞여 있었는데, 섞어 두면 "답해야 할 것"과
/// "이어서 할 것"이 구분되지 않는다.
///
/// **받은 신청은 여기서 수락/거절하지 않는다.** 카드를 누르면 [포스트 정보] 화면이 열리고
/// 거기서 결정한다 — 사진과 한마디를 보고 판단하라는 것이 시안의 뜻이다.
class ChatRoomsScreen extends ConsumerStatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  ConsumerState<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends ConsumerState<ChatRoomsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final rooms = ref.watch(chatRoomsProvider);
    final received = ref.watch(receivedRequestsProvider);

    final roomList = rooms.valueOrNull ?? const <ChatRoomSummary>[];
    final requestList = received.valueOrNull ?? const <ChatRequest>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NightHeader(
          title: l10n.chatRoomsTitle,
          subtitle: l10n.chatRoomsSubtitle,
          child: PillTabs(
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
            tabs: [
              PillTab(
                icon: Icons.chat_bubble_outline_rounded,
                label: l10n.chatTabChats,
                count: roomList.length,
              ),
              PillTab(
                icon: Icons.mail_outline_rounded,
                label: l10n.chatTabReceived,
                count: requestList.length,
              ),
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
            child: _tab == 0
                ? _RoomList(rooms: rooms)
                : _RequestGrid(requests: requestList),
          ),
        ),
      ],
    );
  }
}

class _RoomList extends StatelessWidget {
  const _RoomList({required this.rooms});

  final AsyncValue<List<ChatRoomSummary>> rooms;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final list = rooms.valueOrNull ?? const <ChatRoomSummary>[];

    if (rooms.isLoading && list.isEmpty) return const _Loading();
    if (list.isEmpty) {
      return _Empty(
        icon: Icons.forum_outlined,
        message: l10n.chatRoomsEmpty,
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gapMd,
        AppDimens.gapSm,
        AppDimens.gapMd,
        AppDimens.gapMd,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) => _RoomTile(room: list[i]),
    );
  }
}

/// 대화 목록 한 줄 — 아바타(+미확인 배지) · 이름 나이 국기 시간 접속 · 메시지 · 친구 버튼.
class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});

  final ChatRoomSummary room;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatScreen(room: room)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(url: room.partnerPhotoUrl, unread: room.unreadCount),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _nameAge(room.partnerNickname, room.partnerAge),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (room.flag.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text(room.flag, style: const TextStyle(fontSize: 14)),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(l10n, room.lastMessageAt),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (room.partnerOnline) ...[
                          const SizedBox(width: 8),
                          const _OnlineDot(),
                          const SizedBox(width: 4),
                          Text(
                            l10n.statusOnline,
                            style: const TextStyle(
                              color: AppColors.line,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _preview(l10n, room.lastMessageType, room.lastMessage),
                      // 시안은 원문과 번역을 두 줄로 보여 준다. 번역은 ⑦단계에서
                      // 붙으므로 지금은 원문이 최대 두 줄까지 흐른다.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FriendRelationButton(
                relation: room.friendRelation,
                targetUserId: room.partnerId,
              ),
            ],
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

/// 받은 신청 — **2열 그리드**(기획 6-1). 카드를 누르면 [포스트 정보]로 간다.
class _RequestGrid extends StatelessWidget {
  const _RequestGrid({required this.requests});

  final List<ChatRequest> requests;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    if (requests.isEmpty) {
      return _Empty(
        icon: Icons.mail_outline_rounded,
        message: l10n.chatRequestsEmpty,
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gapMd,
        AppDimens.gapSm,
        AppDimens.gapMd,
        AppDimens.gapMd,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.74,
      ),
      itemCount: requests.length,
      itemBuilder: (context, i) => _RequestCard(request: requests[i]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final ChatRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final photo = request.partnerPhotoUrl;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showPostInfo(context, request.fromUserId),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo == null)
              const ColoredBox(
                color: AppColors.surfaceHigh,
                child: Icon(Icons.person, color: AppColors.textMuted),
              )
            else
              AuthedImage(url: photo),

            // 아래쪽 글자를 살리는 그늘. 탭을 삼키지 않도록 IgnorePointer로 감싼다(함정 #38).
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.nightScrim),
              ),
            ),

            if (request.partnerOnline)
              Positioned(
                left: 8,
                top: 8,
                child: _Badge(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _OnlineDot(),
                      const SizedBox(width: 4),
                      Text(
                        l10n.statusOnline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 아직 답하지 않은 신청 표시(시안의 주황 N).
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _nameAge(request.partnerNickname, request.partnerAge),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (request.flag.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          request.flag,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        _RoomTile._timeAgo(l10n, request.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
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

/// `[친구]` / `[친구 신청]` / `[신청 대기]` — 관계에 따라 글자도 동작도 달라진다.
///
/// 이미 친구이거나 답을 기다리는 중이면 **누를 것이 없다.** 그래도 자리를 비우지 않는 건
/// 지금 어떤 사이인지가 목록에서 바로 보여야 하기 때문이다(기획 6-1 [친구 관계 표시]).
class FriendRelationButton extends ConsumerWidget {
  const FriendRelationButton({
    super.key,
    required this.relation,
    required this.targetUserId,
  });

  final FriendRelation relation;
  final String targetUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);

    final (label, active) = switch (relation) {
      FriendRelation.friend => (l10n.postInfoFriendLabel, false),
      FriendRelation.requested => (l10n.postInfoFriendPending, false),
      FriendRelation.incoming => (l10n.postInfoFriendIncoming, true),
      FriendRelation.none => (l10n.postInfoFriendAdd, true),
    };

    // 누르면 곧바로 보내지 않고 **팝업으로 한 번 보여 준다**(기획 5-1 img13).
    //
    // 목록에 있는 건 이름과 관계뿐이라, 팝업에 넣을 사진·지역·접속은 여기서 다시 묻는다.
    // 한 번 더 부르는 값이지만 그 덕에 팝업이 **지금 상태**를 보여 준다 —
    // 목록이 낡아 이미 수락된 신청에 [친구 수락]이 떠 있었더라도 여기서 드러난다.
    Future<void> act() async {
      final info = await ref.read(postInfoProvider(targetUserId).future);
      if (!context.mounted) return;

      final ApiException? error;
      final String done;
      if (relation == FriendRelation.incoming) {
        final accepted = await showIncomingFriendRequestDialog(
          context,
          info: info,
        );
        if (accepted == null || !context.mounted) return;
        final id = info.friendshipId;
        if (id == null) return;
        error = accepted
            ? await ref.read(friendActionsProvider).accept(id)
            : await ref.read(friendActionsProvider).reject(id);
        done = accepted ? l10n.friendsAccepted : l10n.friendsRejected;
      } else {
        final message = await showFriendRequestDialog(context, info: info);
        if (message == null || !context.mounted) return;
        error = await ref.read(friendActionsProvider).request(
          targetUserId,
          message: message.isEmpty ? null : message,
        );
        done = l10n.friendsRequestSent;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error == null ? done : errorMessage(l10n, error)),
          ),
        );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: active ? act : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.moonlight.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.moonlight : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.moonlight : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

}

String _nameAge(String name, int? age) => age == null ? name : '$name $age';

// ── 작은 조각들 ────────────────────────────────────────────

/// 아바타 + 미확인 배지. 배지는 **읽지 않은 게 있을 때만** 붙는다.
class _Avatar extends StatelessWidget {
  const _Avatar({this.url, this.unread = 0});

  final String? url;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        children: [
          ClipOval(
            child: SizedBox(
              width: 58,
              height: 58,
              child: url == null
                  ? const ColoredBox(
                      color: AppColors.surfaceHigh,
                      child: Icon(Icons.person, color: AppColors.textMuted),
                    )
                  : AuthedImage(url: url!),
            ),
          ),
          if (unread > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.night, width: 2),
                ),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.line,
        shape: BoxShape.circle,
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
  const _Empty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Icon(icon, color: AppColors.textMuted, size: 48),
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
