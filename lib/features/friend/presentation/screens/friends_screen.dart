import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../chat/data/models/chat_models.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../data/models/friend_models.dart';
import '../providers/friend_provider.dart';
import '../widgets/friend_post_sheet.dart';
import '../../../../l10n/app_localizations.dart';

/// 친구 목록. 메인 셸의 l10n.friendsTitle 탭 본문. (기획서 6장)
///
/// 친구는 양방향 — 요청을 보내고 상대가 수락해야 성립한다. 수락하면 상시 대화방이
/// 생겨 운영시간(17~06시) 밖에도 계속 대화할 수 있다.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final friends = ref.watch(friendsProvider);
    final requests = ref.watch(friendRequestsProvider);
    final onlineCount =
        friends.valueOrNull?.where((f) => f.online).length ?? 0;

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
                    l10n.friendsTitle,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _Dot(),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                    onPressed: () =>
                        ref.read(friendsProvider.notifier).refresh(),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    l10n.friendsOnlineNowLabel,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    l10n.friendsOnlineCount(onlineCount),
                    style: const TextStyle(
                      color: AppColors.moonlight,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.gapMd),
              const _FilterBar(),
              const SizedBox(height: AppDimens.gapMd),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.moonlight,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(friendRequestsProvider);
              await ref.read(friendsProvider.notifier).refresh();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 받은 친구 요청
                SliverToBoxAdapter(
                  child: requests.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (list) => list.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppDimens.pagePad,
                              0,
                              AppDimens.pagePad,
                              AppDimens.gapMd,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.friendsRequestsReceived(list.length),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppDimens.gapSm),
                                for (final request in list)
                                  _RequestCard(request: request),
                              ],
                            ),
                          ),
                  ),
                ),
                friends.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.moonlight,
                        ),
                      ),
                    ),
                  ),
                  error: (error, _) => SliverToBoxAdapter(
                    child: _Message(
                      icon: Icons.error_outline,
                      title: l10n.friendsLoadFailed,
                      subtitle: '$error',
                    ),
                  ),
                  data: (list) => list.isEmpty
                      ? SliverToBoxAdapter(
                          child: _Message(
                            icon: Icons.people_outline,
                            title: l10n.friendsEmpty,
                            subtitle:
                                l10n.friendsEmptyHint,
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppDimens.pagePad,
                            0,
                            AppDimens.pagePad,
                            AppDimens.gapMd,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 20,
                                  mainAxisExtent: 180,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _FriendCard(friend: list[i]),
                              childCount: list.length,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 친구 카드 — 누르면 오늘의 포스트 팝업, 길게 누르면 친구 삭제.
class _FriendCard extends ConsumerWidget {
  const _FriendCard({required this.friend});

  final Friend friend;

  void _openRoom(BuildContext context) {
    final l10n = L10n.of(context);
    final roomId = friend.roomId;
    if (roomId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.friendsRoomNotFound)),
        );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          room: ChatRoomSummary(
            roomId: roomId,
            type: 'FRIEND',
            partnerId: friend.userId,
            partnerNickname: friend.nickname,
            partnerAge: friend.age,
            partnerCountry: friend.country,
            partnerPhotoUrl: friend.photoUrl,
            unreadCount: 0,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: Text(
          l10n.friendsDeleteConfirm(friend.nickname),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 17),
        ),
        content: Text(
          l10n.friendsDeleteDetail,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.commonCancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete, style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(friendActionsProvider)
        .remove(friend.friendshipId);
    if (!context.mounted || error == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(errorMessage(l10n, error))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    return InkWell(
      // 카드를 누르면 오늘의 포스트를 먼저 보여준다(기획서 화면 19).
      // 대화방은 그 안의 메시지 버튼으로 간다.
      onTap: () => FriendPostSheet.show(
        context,
        friend: friend,
        onOpenChat: () => _openRoom(context),
      ),
      onLongPress: () => _confirmRemove(context, ref),
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Column(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.moonlight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ClipOval(
                    child: friend.photoUrl == null
                        ? const ColoredBox(
                            color: AppColors.surfaceHigh,
                            child: Icon(
                              Icons.person,
                              color: AppColors.textMuted,
                              size: 36,
                            ),
                          )
                        : AuthedImage(url: friend.photoUrl!),
                  ),
                ),
                if (friend.flag.isNotEmpty)
                  Positioned(
                    bottom: -4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.night,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          friend.flag,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            friend.age == null
                ? friend.nickname
                : '${friend.nickname} ${friend.age}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            friend.intro ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.gold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: friend.online
                    ? const Color(0xFF3FCF6B)
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  friend.online ? l10n.statusOnline : l10n.statusOffline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: friend.online
                        ? const Color(0xFF3FCF6B)
                        : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});

  final FriendRequest request;

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref, {
    required bool accept,
  }) async {
    final l10n = L10n.of(context);
    final actions = ref.read(friendActionsProvider);
    final error = accept
        ? await actions.accept(request.id)
        : await actions.reject(request.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error == null ? (accept ? l10n.friendsAccepted : l10n.friendsRejected) : errorMessage(l10n, error),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.gapSm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: request.partnerPhotoUrl == null
                  ? const ColoredBox(
                      color: AppColors.surfaceHigh,
                      child: Icon(
                        Icons.person,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                    )
                  : AuthedImage(url: request.partnerPhotoUrl!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        request.partnerAge == null
                            ? request.partnerNickname
                            : '${request.partnerNickname} ${request.partnerAge}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(request.flag, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.friendsRequestSent,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _respond(context, ref, accept: false),
            child: Text(
              l10n.commonReject,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.moonlight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () => _respond(context, ref, accept: true),
            child: Text(l10n.commonAccept),
          ),
        ],
      ),
    );
  }
}

/// 성별·나이대·국가 필터. 다시 누르면 해제된다.
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final filter = ref.watch(friendFilterProvider);
    final notifier = ref.read(friendFilterProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            leading: const Icon(Icons.female, size: 18),
            label: filter.gender == 'MALE' ? l10n.genderMale : l10n.genderFemale,
            selected: filter.gender != null,
            onTap: () => notifier.state = switch (filter.gender) {
              null => filter.copyWith(gender: 'FEMALE'),
              'FEMALE' => filter.copyWith(gender: 'MALE'),
              _ => filter.copyWith(clearGender: true),
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FilterChip(
            leading: const Icon(Icons.person_outline, size: 18),
            label: filter.ageMin == null ? l10n.filterAge : l10n.ageDecade(filter.ageMin!),
            selected: filter.ageMin != null,
            onTap: () => notifier.state = switch (filter.ageMin) {
              null => filter.copyWith(ageMin: 20, ageMax: 29),
              20 => filter.copyWith(ageMin: 30, ageMax: 39),
              _ => filter.copyWith(clearAge: true),
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FilterChip(
            leading: Text(
              filter.country == 'JP' ? '🇯🇵' : '🇰🇷',
              style: const TextStyle(fontSize: 15),
            ),
            label: switch (filter.country) {
              'KR' => l10n.countryKorea,
              'JP' => l10n.countryJapan,
              _ => l10n.filterCountry,
            },
            selected: filter.country != null,
            onTap: () => notifier.state = switch (filter.country) {
              null => filter.copyWith(country: 'KR'),
              'KR' => filter.copyWith(country: 'JP'),
              _ => filter.copyWith(clearCountry: true),
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.leading,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.moonlight.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.moonlight : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(
                color: selected
                    ? AppColors.moonlight
                    : AppColors.textSecondary,
              ),
              child: leading,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.moonlight
                      : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePad,
        60,
        AppDimens.pagePad,
        0,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 48),
          const SizedBox(height: AppDimens.gapMd),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
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
