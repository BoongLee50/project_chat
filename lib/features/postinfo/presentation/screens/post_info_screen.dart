import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../chat/data/models/chat_models.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../chat/presentation/widgets/chat_request_dialog.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../../moderation/presentation/widgets/block_dialog.dart';
import '../../../moderation/presentation/widgets/report_dialog.dart';
import '../../../profile/data/models/profile_catalog.dart';
import '../../data/models/post_info.dart';
import '../providers/post_info_provider.dart';

/// [포스트 정보] — 상대 한 사람을 보여 주는 **공통** 풀스크린(기획 6-1 · 7-1 우측).
///
/// 대화방의 받은 신청 카드, 친구 목록 카드, 달빛가든이 모두 이 화면을 연다.
/// 보여 주는 내용은 같고 **하단 버튼만** 다르다.
///
/// **하단 버튼은 부르는 쪽이 정하지 않고 데이터가 정한다** (자세한 순서는 `_Actions`).
///
/// 부르는 쪽이 버튼을 지정하게 두면, 목록이 낡았을 때 이미 수락한 신청에
/// [수락] 버튼이 다시 뜬다. 화면에 들어올 때 서버에 물으므로 여기가 항상 최신이다.
Future<void> showPostInfo(BuildContext context, String targetUserId) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PostInfoScreen(targetUserId: targetUserId),
      fullscreenDialog: true,
    ),
  );
}

class PostInfoScreen extends ConsumerWidget {
  const PostInfoScreen({super.key, required this.targetUserId});

  final String targetUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final info = ref.watch(postInfoProvider(targetUserId));

    return Scaffold(
      backgroundColor: AppColors.night,
      body: info.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (_, _) => _Failed(message: l10n.postInfoLoadFailed),
        data: (data) => _Body(info: data),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.info});

  final PostInfo info;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _controller = PageController();
  int _page = 0;

  PostInfo get _info => widget.info;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 성공하면 화면을 닫는다 — 답을 한 신청은 이 화면에 더 머물 이유가 없다.
  Future<void> _decide(Future<ApiException?> Function() action) async {
    final l10n = L10n.of(context);
    final error = await action();
    if (!mounted) return;
    if (error != null) {
      _toast(errorMessage(l10n, error));
      return;
    }
    Navigator.of(context).pop();
  }

  /// 이미 열려 있는 대화방으로 들어간다.
  ///
  /// 목록에서 온 요약이 아니라 **방금 서버가 준 값**으로 방을 연다 —
  /// 화면에 들어올 때 물었으므로 여기가 항상 최신이다.
  void _openChat() {
    final roomId = _info.chatRoomId;
    if (roomId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          room: ChatRoomSummary(
            roomId: roomId,
            type: _info.friendRelation == FriendRelation.friend
                ? 'FRIEND'
                : 'MATCH',
            partnerId: _info.userId,
            partnerNickname: _info.nickname,
            partnerAge: _info.age,
            partnerCountry: _info.country,
            partnerPhotoUrl: _info.profilePhotoUrl,
            unreadCount: 0,
          ),
        ),
      ),
    );
  }

  Future<void> _requestChat() async {
    final l10n = L10n.of(context);
    final message = await showChatRequestDialog(
      context,
      nickname: _info.nickname,
    );
    if (message == null || !mounted) return;

    final error = await ref
        .read(chatActionsProvider)
        .requestChat(_info.userId, message);
    if (!mounted) return;
    _toast(
      error == null ? l10n.gardenChatRequestSent : errorMessage(l10n, error),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 사진은 화면의 절반을 조금 넘게 — 시안에서 아래 카드 두 장이 함께 보인다.
    final photoHeight = MediaQuery.of(context).size.height * 0.56;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Photos(
                info: _info,
                controller: _controller,
                page: _page,
                onPageChanged: (i) => setState(() => _page = i),
                height: photoHeight,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gapMd,
                  AppDimens.gapMd,
                  AppDimens.gapMd,
                  0,
                ),
                child: _Details(info: _info),
              ),
            ],
          ),
        ),
        _Actions(
          info: _info,
          onDecide: _decide,
          onRequestChat: _requestChat,
          onOpenChat: _openChat,
        ),
      ],
    );
  }
}

/// 사진 + 위에 얹힌 뒤로가기 · `1/9` · ⋮ 메뉴 · 이름줄.
class _Photos extends StatelessWidget {
  const _Photos({
    required this.info,
    required this.controller,
    required this.page,
    required this.onPageChanged,
    required this.height,
  });

  final PostInfo info;
  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final photos = info.photoUrls;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photos.isEmpty)
            const ColoredBox(color: AppColors.surfaceHigh)
          else
            PageView.builder(
              controller: controller,
              itemCount: photos.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, i) => AuthedImage(url: photos[i]),
            ),

          // 이름과 버튼이 사진 위에 있으므로 아래쪽을 어둡게 깔아 글자를 살린다.
          // 탭을 먹지 않도록 IgnorePointer로 감싼다(함정 #38 — 스크림이 터치를 삼킨다).
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.nightScrim),
            ),
          ),

          Positioned(
            left: 4,
            right: 4,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: l10n.commonBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  _OverflowMenu(info: info),
                ],
              ),
            ),
          ),

          // `1/9`는 **원래 장수**를 쓴다 — 열람 제한으로 1장만 받았어도
          // "더 있다"가 보여야 안내가 말이 된다.
          if (info.hasTodayPost && info.totalPhotos > 0)
            Positioned(
              right: AppDimens.gapMd,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 56),
                  child: _Pill(
                    child: Text(
                      '${page + 1}/${info.totalPhotos}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (!info.hasTodayPost)
            Positioned(
              left: 0,
              right: 0,
              top: height * 0.42,
              child: Text(
                l10n.postInfoNoPost,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),

          Positioned(
            left: AppDimens.gapMd,
            right: AppDimens.gapMd,
            bottom: AppDimens.gapMd,
            child: _NameRow(info: info),
          ),
        ],
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.info});

  final PostInfo info;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            info.age == null ? info.nickname : '${info.nickname} ${info.age}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (info.country != null) ...[
          const SizedBox(width: 8),
          Text(
            ProfileCatalog.countryFlag(info.country!),
            style: const TextStyle(fontSize: 18),
          ),
        ],
        if (info.online) ...[
          const SizedBox(width: 8),
          const _OnlineDot(),
        ],
      ],
    );
  }
}

/// ⋮ — 프로필 보기 / 신고하기 / 차단하기 (+ 친구면 친구 해제).
class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu({required this.info});

  final PostInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      color: AppColors.surface,
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            await showDialog<void>(
              context: context,
              builder: (_) => _ProfileDialog(info: info),
            );
          case 'report':
            final done = await ReportDialog.show(
              context,
              targetUserId: info.userId,
              targetNickname: info.nickname,
            );
            // 신고하면 대화가 끊기므로 이 화면에 남아 있을 이유가 없다.
            if (done == true && context.mounted) Navigator.of(context).pop();
          case 'block':
            final done = await BlockDialog.show(
              context,
              targetUserId: info.userId,
              targetNickname: info.nickname,
            );
            if (done == true && context.mounted) Navigator.of(context).pop();
          case 'unfriend':
            final id = info.friendshipId;
            if (id == null) return;
            final error = await ref.read(friendActionsProvider).remove(id);
            if (!context.mounted) return;
            if (error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(errorMessage(l10n, error))),
                );
              return;
            }
            Navigator.of(context).pop();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: _MenuRow(
            icon: Icons.person_outline_rounded,
            label: l10n.postInfoMenuProfile,
          ),
        ),
        PopupMenuItem(
          value: 'report',
          child: _MenuRow(
            icon: Icons.error_outline_rounded,
            label: l10n.chatMenuReport,
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: _MenuRow(
            icon: Icons.block_rounded,
            label: l10n.chatMenuBlock,
          ),
        ),
        // 친구가 아닌 사람에게 [친구 해제]를 보여 주면 무슨 일이 일어날지 알 수 없다.
        if (info.friendRelation == FriendRelation.friend)
          PopupMenuItem(
            value: 'unfriend',
            child: _MenuRow(
              icon: Icons.person_remove_outlined,
              label: l10n.postInfoMenuUnfriend,
            ),
          ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
      ],
    );
  }
}

/// [프로필 보기] — 포스트 사진이 아니라 **프로필 사진**과 활동 지역을 보여 준다.
/// 포스트 사진은 열람 제한이 걸리지만 프로필은 원래 누구나 본다.
class _ProfileDialog extends StatelessWidget {
  const _ProfileDialog({required this.info});

  final PostInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final photo = info.profilePhotoUrl;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        l10n.postInfoProfileTitle(info.nickname),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 17),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              width: 96,
              height: 96,
              child: photo == null
                  ? const ColoredBox(
                      color: AppColors.surfaceHigh,
                      child: Icon(Icons.person, color: AppColors.textMuted),
                    )
                  : AuthedImage(url: photo),
            ),
          ),
          const SizedBox(height: AppDimens.gapMd),
          if (info.regions.isNotEmpty) ...[
            Text(
              l10n.postInfoRegions,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimens.gapSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in info.regions)
                  _Chip(label: ProfileCatalog.regionLabel(l10n, code)),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}

/// 대화 신청 메시지 → 관심사 → 소개 한마디.
class _Details extends StatelessWidget {
  const _Details({required this.info});

  final PostInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final message = info.quotedMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 시안은 신청 메시지를 **따옴표로 감싼** 한 줄로 둔다 — 프로필 문구가 아니라
        // 상대가 나에게 한 말이라는 걸 보이게 하려는 것이다.
        if (message != null && message.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Text(
              '"$message"',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.gapSm),
        ],

        if (info.interests.isNotEmpty)
          _Card(
            icon: Icons.favorite_border_rounded,
            title: l10n.profileInterests,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in info.interests)
                  _Chip(label: ProfileCatalog.interestLabel(l10n, code)),
              ],
            ),
          ),

        if (info.intro != null && info.intro!.isNotEmpty)
          _Card(
            icon: Icons.format_quote_rounded,
            title: l10n.profileIntro,
            child: Text(
              info.intro!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}

/// 하단 버튼. **어디서 왔는지가 아니라 지금 상태**가 정한다(위 클래스 주석 참고).
///
/// 순서에 뜻이 있다:
/// 1. 답하지 않은 **대화 신청** → `[✕ 거절] [✓ 수락]`
/// 2. 답하지 않은 **친구 신청** → 같은 두 버튼(친구 쪽으로)
/// 3. 이미 열려 있는 대화방 → `[💬 대화하기]`
/// 4. 그 외 → `[대화 신청]`
///
/// 답해야 할 것이 먼저다. 친구 목록에서 들어왔더라도 아직 답하지 않은 신청이 있다면
/// 그 결정을 먼저 보여 주는 게 맞다.
class _Actions extends ConsumerWidget {
  const _Actions({
    required this.info,
    required this.onDecide,
    required this.onRequestChat,
    required this.onOpenChat,
  });

  final PostInfo info;
  final Future<void> Function(Future<ApiException?> Function()) onDecide;
  final VoidCallback onRequestChat;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final chatRequestId = info.chatRequestId;
    final friendshipId = info.friendshipId;
    final incomingFriend =
        info.friendRelation == FriendRelation.incoming && friendshipId != null;

    final Widget content;
    if (chatRequestId != null) {
      content = _Decide(
        onReject: () =>
            onDecide(() => ref.read(chatActionsProvider).reject(chatRequestId)),
        onAccept: () =>
            onDecide(() => ref.read(chatActionsProvider).accept(chatRequestId)),
      );
    } else if (incomingFriend) {
      content = _Decide(
        onReject: () => onDecide(
          () => ref.read(friendActionsProvider).reject(friendshipId),
        ),
        onAccept: () => onDecide(
          () => ref.read(friendActionsProvider).accept(friendshipId),
        ),
      );
    } else {
      final canChat = info.chatRoomId != null;
      content = SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: canChat ? onOpenChat : onRequestChat,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: Text(canChat ? l10n.postInfoChat : l10n.postInfoRequestChat),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.moonlight,
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gapMd,
          AppDimens.gapMd,
          AppDimens.gapMd,
          AppDimens.gapSm,
        ),
        child: content,
      ),
    );
  }
}

class _Decide extends StatelessWidget {
  const _Decide({required this.onReject, required this.onAccept});

  final VoidCallback onReject;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(l10n.commonReject),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(l10n.commonAccept),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.moonlight,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 작은 조각들 ────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimens.gapSm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.moonlight),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapSm),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
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
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: AppColors.line,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
            ),
          ),
          Center(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
