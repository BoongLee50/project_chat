import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/night_header.dart';
import '../../../postinfo/presentation/screens/post_info_screen.dart';
import '../../../profile/data/models/profile_catalog.dart';
import '../../data/models/friend_models.dart';
import '../providers/friend_provider.dart';

/// 친구 — 메인 셸의 l10n.friendsTitle 탭 본문. (기획 7-1)
///
/// 탭이 **둘**이다: `[👤 친구 목록]`은 3열 그리드, `[✉ 받은 신청]`은 신청 목록.
/// 어느 쪽이든 **누르면 [포스트 정보]로 간다** — 친구는 대화하러, 신청은 답하러.
///
/// **필터 칩이 없다.** 예전에는 성별·나이·국가 칩 셋이 있었는데 시안에 없다.
/// 친구는 이미 내가 고른 사람들이라 걸러 볼 이유가 약하고, 화면에서 없앤다고
/// 서버가 못 하게 되는 것도 아니다(질의는 그대로 필터를 받는다).
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final friends = ref.watch(friendsProvider);
    final requests = ref.watch(friendRequestsProvider);

    final friendList = friends.valueOrNull ?? const <Friend>[];
    final requestList = requests.valueOrNull ?? const <FriendRequest>[];
    final onlineCount = friendList.where((f) => f.online).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NightHeader(
          title: l10n.friendsTitle,
          subtitle: '${l10n.friendsOnlineNowLabel}${l10n.friendsOnlineCount(onlineCount)}',
          child: PillTabs(
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
            tabs: [
              PillTab(
                icon: Icons.people_outline_rounded,
                label: l10n.friendsTabList,
                count: friendList.length,
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
              ref.invalidate(friendRequestsProvider);
              await ref.read(friendsProvider.notifier).refresh();
            },
            child: _tab == 0
                ? _FriendGrid(friends: friends)
                : _RequestList(requests: requestList),
          ),
        ),
      ],
    );
  }
}

/// 3열 그리드 — 원형 사진(국기 배지) · 이름 나이 · 도시 · 접속 상태.
class _FriendGrid extends StatelessWidget {
  const _FriendGrid({required this.friends});

  final AsyncValue<List<Friend>> friends;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final list = friends.valueOrNull ?? const <Friend>[];

    if (friends.isLoading && list.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.moonlight),
      );
    }
    if (friends.hasError && list.isEmpty) {
      return _Message(
        icon: Icons.error_outline,
        title: l10n.friendsLoadFailed,
        subtitle: '',
      );
    }
    if (list.isEmpty) {
      return _Message(
        icon: Icons.people_outline,
        title: l10n.friendsEmpty,
        subtitle: l10n.friendsEmptyHint,
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
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 18,
        mainAxisExtent: 176,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) => _FriendCard(friend: list[i]),
    );
  }
}

/// 친구 카드 — 누르면 [포스트 정보].
///
/// 예전에는 오늘의 포스트 팝업이 떴다. 시안이 이 카드에 붙인 것은 [포스트 정보]이고,
/// 그 화면에 사진·관심사·소개·대화하기가 모두 있어 팝업이 하던 일을 대신한다.
class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showPostInfo(context, friend.userId),
      child: Column(
        children: [
          SizedBox(
            width: 84,
            height: 88,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: friend.online
                          ? AppColors.moonlight
                          : AppColors.border,
                      width: friend.online ? 2 : 1,
                    ),
                  ),
                  child: ClipOval(
                    child: friend.photoUrl == null
                        ? const ColoredBox(
                            color: AppColors.surfaceHigh,
                            child: Icon(
                              Icons.person,
                              color: AppColors.textMuted,
                              size: 34,
                            ),
                          )
                        : AuthedImage(url: friend.photoUrl!),
                  ),
                ),
                if (friend.flag.isNotEmpty)
                  Positioned(
                    left: 2,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.night,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        friend.flag,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
          // 시안은 이 자리에 **도시**를 둔다(예전에는 소개 한마디였다).
          Text(
            friend.region == null
                ? ''
                : ProfileCatalog.cityLabel(l10n, friend.region!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.gold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          _PresenceLine(friend: friend),
        ],
      ),
    );
  }
}

/// `● 온라인` / `● 1시간 전 접속` / `● 접속 기록 없음`.
///
/// 색이 세 가지인 건 장식이 아니다 — 지금 있는 사람, 방금까지 있던 사람,
/// 오래 안 온 사람을 한눈에 가르려는 것이다(시안 7-1).
class _PresenceLine extends StatelessWidget {
  const _PresenceLine({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final (label, color) = _describe(l10n);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 11),
          ),
        ),
      ],
    );
  }

  (String, Color) _describe(L10n l10n) {
    if (friend.online) return (l10n.statusOnline, AppColors.line);

    final seen = friend.lastSeenAt;
    if (seen == null) return (l10n.friendsNeverSeen, AppColors.textMuted);

    final diff = DateTime.now().difference(seen);
    final ago = switch (diff) {
      _ when diff.inMinutes < 1 => l10n.timeJustNow,
      _ when diff.inMinutes < 60 => l10n.timeMinutesAgo(diff.inMinutes),
      _ when diff.inHours < 24 => l10n.timeHoursAgo(diff.inHours),
      _ => l10n.timeDaysAgo(diff.inDays),
    };
    // 한나절 안쪽이면 아직 "곧 돌아올 사람"으로 본다.
    final color = diff.inHours < 12 ? AppColors.gold : AppColors.textMuted;
    return (l10n.friendsLastSeen(ago), color);
  }
}

/// 받은 친구 신청 — 목록(그리드가 아니다, 시안 7-1 우측 탭).
/// 신청과 함께 온 **한마디**가 이름 아래에 온다. 누르면 [포스트 정보]에서 답한다.
class _RequestList extends StatelessWidget {
  const _RequestList({required this.requests});

  final List<FriendRequest> requests;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    if (requests.isEmpty) {
      return _Message(
        icon: Icons.mail_outline_rounded,
        title: l10n.friendsRequestsEmpty,
        subtitle: '',
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
      itemCount: requests.length,
      itemBuilder: (context, i) => _RequestTile(request: requests[i]),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final FriendRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showPostInfo(context, request.requesterId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 66,
              height: 66,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    child: SizedBox(
                      width: 66,
                      height: 66,
                      child: request.partnerPhotoUrl == null
                          ? const ColoredBox(
                              color: AppColors.surfaceHigh,
                              child: Icon(
                                Icons.person,
                                color: AppColors.textMuted,
                              ),
                            )
                          : AuthedImage(url: request.partnerPhotoUrl!),
                    ),
                  ),
                  if (request.flag.isNotEmpty)
                    Positioned(
                      left: 3,
                      bottom: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.night.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          request.flag,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
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
                      if (request.partnerOnline) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.circle,
                          size: 7,
                          color: AppColors.line,
                        ),
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
                  const SizedBox(height: 3),
                  Text(
                    _timeAgo(l10n, request.createdAt),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // 한마디가 없으면 아무것도 쓰지 않는다. 예전에는 "친구 요청을 보냈어요"를
                  // 채워 넣었는데, 그건 **상대가 한 말이 아니었다**.
                  if (request.message != null && request.message!.isNotEmpty)
                    Text(
                      request.message!,
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
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppDimens.pagePad, 60, AppDimens.pagePad, 0),
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
        if (subtitle.isNotEmpty) ...[
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
      ],
    );
  }
}
