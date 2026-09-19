import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/art_top_bar.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../chat/presentation/widgets/talk_art.dart';
import '../../../chat/presentation/widgets/talk_cell.dart';
import '../../../profile/data/models/profile_catalog.dart';
import '../../data/models/friend_models.dart';
import '../providers/friend_provider.dart';
import '../widgets/friend_art.dart';
import 'friend_post_screen.dart';
import 'friend_request_screen.dart';

/// 친구 — `[친구 목록]` · `[받은 신청]` 두 탭(기획서 260919 7-1·7-2, `Scene_Friend` 전달본).
///
/// **[친구 목록]** — 원형 사진 3열. 순서는 **서버가 정해서** 준다:
/// 상단 고정 > 신규 등록(수락 후 7일) > 온라인 > 최근 접속. 고정·신규가 여럿이면 최신순.
/// - 고정이면 핀, 신규면 `N`(같은 자리 — 고정이 먼저다), 원 아래에 국기.
/// - 이름·나이 / 도시 / 접속(`● ON` 그림, 아니면 "N시간 전 접속" 글자 — 기획서 "마지막 접속 시간").
/// - 탭 숫자 = **신규 등록 수**(기획서 — "신규 등록 목록이 존재하면 그 갯수", 99가 최대).
/// - 프로필 사진을 누르면 **[친구 포스트 정보]**.
///
/// **[받은 신청]** — 🚨 *"화면 구성과 기능은 [대화 목록]창과 동일"*. 대화방 셀을 **그대로** 쓴다.
/// 탭 숫자 = 아직 안 열어 본 신청 수. 누르면 **[친구 요청 상세]**.
///
/// 260906판에 있던 성별·나이·국가 필터는 없다(시안에 없다). 서버 질의는 필터를 그대로 받는다.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final friends = ref.watch(friendsProvider);
    final requests = ref.watch(friendRequestsProvider);

    final friendList = friends.valueOrNull ?? const <Friend>[];
    final requestList = requests.valueOrNull ?? const <FriendRequest>[];
    final newCount = friendList.where((f) => f.newlyAdded).length;
    final unviewed = requestList.where((r) => !r.viewed).length;

    // 시안 배경은 **화면 맨 위까지** 올라간다 — 상태바 높이는 화면(View)에서 읽는다(함정 #32).
    final statusBar = MediaQueryData.fromView(View.of(context)).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -statusBar,
          left: 0,
          right: 0,
          child: Image.asset(
            FriendArt.background,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: DesignCanvas.titleTopInSafeArea(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: 47 * s,
                  right: DesignCanvas.contentLeft * s,
                ),
                child: const ArtTopBar(
                  title: FriendArt.title,
                  titleSize: FriendArt.titleSize,
                ),
              ),
              SizedBox(height: DesignCanvas.headerToRow * s),
              ArtTabs(
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
                leftOn: FriendArt.tabFriendsOn,
                leftOff: FriendArt.tabFriendsOff,
                rightOn: FriendArt.tabReceiveOn,
                rightOff: FriendArt.tabReceiveOff,
                leftCount: newCount,
                rightCount: unviewed,
              ),
              // 받은 신청은 대화방과 같은 자리(탭 아래 → 첫 셀 499). 친구 목록은 격자가
              // 여백을 품는다 — 첫 줄의 핀이 원 위로 19px 튀어나와 잘리지 않게.
              if (_tab == 1)
                SizedBox(height: (499 - 356 - TalkArt.tabSize.height) * s),
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
                      : _RequestGrid(
                          requests: requests,
                          onAccepted: () => setState(() => _tab = 0),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── [친구 목록] ─────────────────────────────────────────────
class _FriendGrid extends StatelessWidget {
  const _FriendGrid({required this.friends});

  final AsyncValue<List<Friend>> friends;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final list = friends.valueOrNull ?? const <Friend>[];

    if (friends.isLoading && list.isEmpty) return const CellLoading();
    if (friends.hasError && list.isEmpty) {
      return CellEmpty(message: l10n.friendsLoadFailed);
    }
    if (list.isEmpty) {
      return CellEmpty(message: '${l10n.friendsEmpty}\n${l10n.friendsEmptyHint}');
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        FriendArt.gridLeft * s,
        FriendArt.tabsToGrid * s,
        FriendArt.gridLeft * s,
        40 * s,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: FriendArt.gridGapX * s,
        mainAxisSpacing: 0,
        // 한 칸 = 원(315) + 글 세 줄. 줄 간격 570이 곧 칸 높이다.
        childAspectRatio: FriendArt.circleSize.width / FriendArt.rowPitch,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) => _FriendCircle(
        friend: list[i],
        onTap: () =>
            Navigator.of(context).push(FriendPostScreen.route(list[i])),
      ),
    );
  }
}

/// 원형 칸 하나 — 시안 `친구방_친구목록 좌표값`의 한 칸(315 폭).
class _FriendCircle extends StatelessWidget {
  const _FriendCircle({required this.friend, required this.onTap});

  final Friend friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final d = FriendArt.circleSize.width * s;
    final inset = FriendArt.circlePhotoInset * s;
    final flag = FriendArt.flagOf(friend.country);
    final city = friend.region == null
        ? null
        : ProfileCatalog.cityLabel(l10n, friend.region!);

    Widget centered(double top, Widget child) => Positioned(
      left: 0,
      right: 0,
      top: top * s,
      child: Center(child: child),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 사진 → 원형 테두리 그림.
          SizedBox(
            width: d,
            height: d,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.all(inset),
                  child: ClipOval(
                    // 사진이 없으면 빈 원 그대로(아이콘을 그려 넣지 않는다 — 14 §3).
                    child: friend.photoUrl == null
                        ? const ColoredBox(color: AppColors.night)
                        : AuthedImage(url: friend.photoUrl!),
                  ),
                ),
                IgnorePointer(
                  child: Image.asset(FriendArt.circleFrame, fit: BoxFit.fill),
                ),
              ],
            ),
          ),
          // 고정 핀 · 신규 N — **같은 자리**라 하나만 선다. 고정이 먼저다(목록 순서도 고정이 위).
          if (friend.pinned || friend.newlyAdded)
            Positioned(
              left: FriendArt.pinSmallAt.dx * s,
              top: FriendArt.pinSmallAt.dy * s,
              child: friend.pinned
                  ? const ArtImage(
                      FriendArt.pinSmall,
                      width: 56,
                      height: 55,
                    )
                  : ArtImage(
                      TalkArt.newMark,
                      width: TalkArt.newMarkSize.width,
                      height: TalkArt.newMarkSize.height,
                    ),
            ),
          if (flag != null)
            Positioned(
              left: FriendArt.flagAt.dx * s,
              top: FriendArt.flagAt.dy * s,
              child: ArtImage(
                flag,
                width: FriendArt.flagSize.width,
                height: FriendArt.flagSize.height,
              ),
            ),
          centered(
            FriendArt.nameTop,
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    friend.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44 * s,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (friend.age != null) ...[
                  SizedBox(width: 12 * s),
                  Text(
                    '${friend.age}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 40 * s,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (city != null)
            centered(
              FriendArt.cityTop,
              Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.gold, fontSize: 36 * s),
              ),
            ),
          centered(FriendArt.presenceTop, _Presence(friend: friend)),
        ],
      ),
    );
  }
}

/// 접속 표시 — 온라인이면 `● ON` 그림, 아니면 **마지막 접속 시간**(글자 — 값이 변한다, 14 §3).
///
/// 기획서 7-1: *"[친구 기본 정보]는 … 마지막 접속 시간 표시"* · *"온라인 접속 상태일 경우 온라인 마크 출력"*.
class _Presence extends StatelessWidget {
  const _Presence({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    if (friend.online) {
      return ArtImage(
        FriendArt.online,
        width: FriendArt.onlineSize.width,
        height: FriendArt.onlineSize.height,
      );
    }
    final l10n = L10n.of(context);
    final seen = friend.lastSeenAt;
    final label = seen == null
        ? l10n.friendsNeverSeen
        : l10n.friendsLastSeen(_ago(l10n, seen));
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: AppColors.textMuted, fontSize: 30 * s),
    );
  }

  static String _ago(L10n l10n, DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    return l10n.timeDaysAgo(diff.inDays);
  }
}

// ── [받은 신청] — 대화방 셀 그대로 ────────────────────────────
class _RequestGrid extends ConsumerWidget {
  const _RequestGrid({required this.requests, required this.onAccepted});

  final AsyncValue<List<FriendRequest>> requests;
  final VoidCallback onAccepted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final list = requests.valueOrNull ?? const <FriendRequest>[];
    if (requests.isLoading && list.isEmpty) return const CellLoading();
    if (list.isEmpty) return CellEmpty(message: l10n.friendsRequestsEmpty);

    return CellGrid(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final r = list[i];
        return TalkCell(
          photoUrl: r.partnerPhotoUrl,
          nickname: r.partnerNickname,
          age: r.partnerAge,
          country: r.partnerCountry,
          online: r.partnerOnline,
          // 받은 신청의 '미확인'은 **아직 안 열어 본 신청**이다(V27 — 대화방 V26과 같은 뜻).
          unconfirmed: !r.viewed,
          at: r.createdAt,
          // 친구 요청 메시지 25자 + `…`(기획서 7-2).
          text: r.message,
          onTap: () async {
            final accepted = await Navigator.of(
              context,
            ).push(FriendRequestScreen.route(r));
            // 열어 본 순간 서버가 '확인함'으로 바꾼다 — 돌아오면 N이 지워진 목록을 다시 읽는다.
            ref.invalidate(friendRequestsProvider);
            // 수락했으면 새 친구가 **맨 위(신규 등록)** 에 N과 함께 보이는 [친구 목록]으로 넘긴다.
            if (accepted == true) onAccepted();
          },
        );
      },
    );
  }
}
