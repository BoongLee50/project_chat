import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../app/main_shell.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/util/freshness.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../data/models/feed_item.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../profile/data/models/profile_catalog.dart';
import '../../../store/presentation/screens/luna_store_screen.dart';
import '../../../store/presentation/screens/prime_screen.dart';
import '../providers/garden_provider.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/garden_art.dart';
import '../../../../l10n/app_localizations.dart';

/// 달빛가든 — 포스트 사진 피드. 메인 셸의 l10n.gardenTitle 탭 본문. (기획서 4장)
///
/// 필터(성별·연령대·국가)·좋아요·스킵(스와이프)·댓글을 서버와 연동한다.
/// 대화 신청은 chat 도메인 구현 후 연결 예정.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final feed = ref.watch(feedProvider);
    final scale = GardenArt.scaleOf(context);

    // 피드는 소켓으로 알려줄 방법이 없어, 탭에 다시 들어왔을 때 낡았으면 조용히 다시 읽는다.
    // (스킵했던 사람이 사진·프로필을 갱신하면 다시 뜨는 걸 여기서 반영한다)
    // 셸이 SafeArea로 상태바만큼 밀어 놨지만, 시안은 배경이 **화면 맨 위까지** 올라간다.
    // SafeArea 안에서는 padding·viewPadding이 둘 다 깎여 상태바 높이를 알 수 없으므로,
    // 화면(View)에서 직접 읽는다.
    final statusBar = MediaQueryData.fromView(View.of(context)).padding.top;

    return RefreshOnVisible(
      isVisible: ref.watch(selectedTabProvider) == MainTab.garden,
      onStale: () => ref.read(feedProvider.notifier).refreshIfStale(),
      child: Stack(
        // 배경을 상태바 뒤까지 올리려면 Stack이 자르지 않아야 한다(기본값은 자름).
        clipBehavior: Clip.none,
        children: [
          // 시안 배경(정원 야경) — 상태바 뒤까지 덮고 아래는 어둠으로 이어진다.
          Positioned(
            top: -statusBar,
            left: 0,
            right: 0,
            child: Image.asset(
              GardenArt.background,
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              // 하단 5탭과 **좌우 폭을 맞춘다**(시안에서 카드와 내비가 같은 선에 있다).
              AppDimens.navSidePad,
              // 시안 타이틀 위치(3.74 단위)에 맞춘다.
              GardenArt.unit * 3.74 * scale,
              AppDimens.navSidePad,
              AppDimens.gapMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 시안에서 타이틀(1.66)은 카드·필터(0.93~0.95)보다 안쪽에 있다 — 그만큼만 더 준다.
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: GardenArt.unit * (1.66 - 0.93) * scale,
                  ),
                  child: const _GardenHeader(),
                ),
                const SizedBox(height: AppDimens.gapMd),
                const _FilterBar(),
                const SizedBox(height: AppDimens.gapMd),
                Expanded(
                  child: feed.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.moonlight,
                      ),
                    ),
                    error: (error, _) => _Message(
                      icon: Icons.cloud_off,
                      title: l10n.gardenLoadFailed,
                      detail: '$error',
                      onRetry: () => ref.read(feedProvider.notifier).refresh(),
                    ),
                    data: (items) => items.isEmpty
                        ? _Message(
                            icon: Icons.nightlight_round,
                            title: l10n.gardenEmptyTitle,
                            detail: l10n.gardenEmptyDetail,
                            onRetry: () =>
                                ref.read(feedProvider.notifier).refresh(),
                          )
                        : _FeedPager(items: items),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 헤더 ─────────────────────────────────────────────────
class _GardenHeader extends StatelessWidget {
  const _GardenHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀은 **이미지**다(글자가 구워져 있음). 일본어판은 이미지를 교체한다.
              const ArtImage(GardenArt.title, width: 278, height: 71),
              const SizedBox(height: 6),
              // 부제는 **폰트**다 — ARB가 그리므로 언어를 따라간다.
              Text(
                l10n.gardenSubtitle,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
        // Prime · 루나상점 진입(시안 20.38 / 29.58 위치)
        GestureDetector(
          onTap: () => Navigator.of(context).push(PrimeScreen.route()),
          child: const ArtImage(GardenArt.btnPrime, width: 248, height: 83),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.of(context).push(LunaStoreScreen.route()),
          child: const ArtImage(GardenArt.btnLuna, width: 216, height: 83),
        ),
      ],
    );
  }
}

// ── 필터 바 ──────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final filter = ref.watch(feedFilterProvider);
    final controller = ref.read(feedFilterProvider.notifier);

    // 필터 칩은 전 상태의 그림이 있다(전체 포함) — 텍스트 폴백이 필요 없다.
    // 누르면 뜨는 **드롭다운 목록의 글자는 ARB**다(폰트). 칩만 이미지다.
    //
    // 시안(4-1)의 이 줄은 **네 칸**이다 — 성별·나이·국가 칩 셋 + **[달빛 한마디] 버튼**.
    // 폐지된 스포트라이트 칩 자리에 같은 크기로 들어가는 **데일리 참여 이벤트 진입점**이고,
    // ⑤단계에서 화면과 함께 만든다. 배율은 네 칸 기준이라(GardenArt.filterRowScale)
    // 지금은 오른쪽에 그 버튼 자리만큼 여백이 남는다 — 비어 보이는 게 맞다.
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = GardenArt.filterRowScale(constraints.maxWidth);
        final gap = GardenArt.filterGap * s;
        return Row(
          children: [
            _ArtMenu<String>(
              art: GardenArt.genderChip(filter.gender),
              size: GardenArt.filterGenderSize,
              scale: s,
              options: {
                l10n.commonAll: null,
                l10n.genderFemale: 'FEMALE',
                l10n.genderMale: 'MALE',
              },
              current: filter.gender,
              onPick: controller.selectGender,
            ),
            SizedBox(width: gap),
            _ArtMenu<int>(
              art: GardenArt.ageChip(filter.ageDecade),
              size: GardenArt.filterAgeSize,
              scale: s,
              options: {
                l10n.commonAll: null,
                l10n.ageDecade(10): 10,
                l10n.ageDecade(20): 20,
                l10n.ageDecade(30): 30,
                l10n.ageDecade(40): 40,
              },
              current: filter.ageDecade,
              onPick: controller.selectAge,
            ),
            SizedBox(width: gap),
            _ArtMenu<String>(
              art: GardenArt.countryChip(filter.country),
              size: GardenArt.filterCountrySize,
              scale: s,
              options: {
                l10n.commonAll: null,
                l10n.countryKorea: 'KR',
                l10n.countryJapan: 'JP',
              },
              current: filter.country,
              onPick: controller.selectCountry,
            ),
          ],
        );
      },
    );
  }
}

/// 시안 칩(이미지)을 누르면 드롭다운이 뜬다.
/// **칩은 이미지, 목록 글자는 ARB** — 이 앱의 UI 언어 두 종류가 한 위젯에 같이 있다.
class _ArtMenu<T> extends StatelessWidget {
  const _ArtMenu({
    required this.art,
    required this.size,
    required this.scale,
    required this.options,
    required this.current,
    required this.onPick,
  });

  final String art;

  /// 시안 원본 픽셀(1080 캔버스 기준).
  final Size size;

  /// 필터 바가 한 줄에 딱 맞도록 계산한 배율.
  final double scale;

  /// 표시명 → 값(전체는 null)
  final Map<String, T?> options;
  final T? current;
  final ValueChanged<T?> onPick;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.surfaceHigh,
      onSelected: (name) => onPick(options[name]),
      itemBuilder: (context) => [
        for (final entry in options.entries)
          PopupMenuItem(
            value: entry.key,
            child: Text(
              entry.key,
              style: TextStyle(
                color: entry.value == current
                    ? AppColors.moonlight
                    : AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
      ],
      child: ArtImage(
        art,
        width: size.width,
        height: size.height,
        scale: scale,
      ),
    );
  }
}

// ── 피드 카드 ────────────────────────────────────────────
/// 좌우 스와이프로 스킵하며 다음 카드로 넘어간다(기획서 4-1).
class _FeedPager extends ConsumerStatefulWidget {
  const _FeedPager({required this.items});

  final List<FeedItem> items;

  @override
  ConsumerState<_FeedPager> createState() => _FeedPagerState();
}

class _FeedPagerState extends ConsumerState<_FeedPager> {
  int _photoIndex = 0;

  /// 잠긴 사진을 넘기려 했는가 — 안내창은 **시도했을 때만** 뜬다(기획 4-1).
  /// 처음부터 띄워 두면 사진을 볼 생각도 없던 사람에게 광고가 되고, 카드가 가려진다.
  bool _lockNotice = false;

  FeedItem get _item => widget.items.first;

  Future<void> _skip() async {
    // Dismissible이 위젯을 제거한 뒤 async가 이어지므로,
    // await 이전에 notifier를 확보해 둔다(dispose 후 ref 사용 방지).
    final notifier = ref.read(feedProvider.notifier);
    final nearlyEmpty = widget.items.length <= 2;
    _photoIndex = 0;
    _lockNotice = false;

    final error = await notifier.skip(_item);
    if (error != null && mounted) _toast(errorMessage(L10n.of(context), error));
    // 목록이 얼마 안 남으면 다음 페이지를 이어붙인다.
    if (nearlyEmpty) notifier.loadMore();
  }

  Future<void> _like() async {
    final error = await ref.read(feedProvider.notifier).like(_item);
    if (error != null && mounted) _toast(errorMessage(L10n.of(context), error));
  }

  /// 대화 신청 팝업 — 하루 무료 2회 후 루나 5 차감(서버 판정).
  Future<void> _requestChat(FeedItem item) async {
    final l10n = L10n.of(context);
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.gardenChatRequestTitle(item.nickname),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          maxLines: 3,
          cursorColor: AppColors.moonlight,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.gardenChatRequestHint,
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.commonSend),
          ),
        ],
      ),
    );

    if (message == null || message.isEmpty || !mounted) return;
    final error = await ref
        .read(chatActionsProvider)
        .requestChat(item.userId, message);
    if (!mounted) return;
    _toast(
      error == null ? l10n.gardenChatRequestSent : errorMessage(l10n, error),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final photos = item.photoUrls;
    final index = photos.isEmpty ? 0 : _photoIndex.clamp(0, photos.length - 1);
    // 사진을 넘겨 보는 중에는 하루 한마디 대신 관심사를 노출(기획서 4-1).
    final showInterests = index > 0 && item.interests.isNotEmpty;

    return Dismissible(
      key: ValueKey(item.userId),
      onDismissed: (_) => _skip(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            // 시안 외곽선의 라운드와 맞춘다. 값이 다르면 프레임 모서리가 잘려 보인다.
            borderRadius: BorderRadius.circular(GardenArt.cardCornerRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photos.isEmpty)
                  const ColoredBox(color: AppColors.surface)
                else
                  GestureDetector(
                    // ⚠️ opaque가 없으면 **탭이 아예 안 들어온다.** GestureDetector의 기본값은
                    // deferToChild이고 Image는 자기 자신을 히트테스트하지 않아, 사진 위를 눌러도
                    // 아무 일이 일어나지 않는다(함정 #38).
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final width = context.size?.width ?? 1;
                      final forward = details.localPosition.dx > width / 2;
                      // 잠긴 다음 장을 넘기려 하면 사진 대신 안내창을 띄운다.
                      if (forward &&
                          index == photos.length - 1 &&
                          item.photoLocked) {
                        setState(() => _lockNotice = true);
                        return;
                      }
                      final next = forward ? index + 1 : index - 1;
                      setState(
                        () => _photoIndex = next.clamp(0, photos.length - 1),
                      );
                    },
                    child: AuthedImage(url: photos[index]),
                  ),

                // 가독성 스크림.
                //
                // ⚠️ **IgnorePointer가 반드시 있어야 한다.** `DecoratedBox`는 자기 자신을
                // 히트테스트하고(`RenderDecoratedBox.hitTestSelf` → `BoxDecoration.hitTest`는
                // 사각형 안이면 true), 이게 카드 전체를 덮고 있어서 **아래 사진의 탭을 전부
                // 먹어 버린다.** 좌우로 넘겨 보는 기능이 그동안 조용히 죽어 있던 원인이다(함정 #38).
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x99000000),
                          Color(0x00000000),
                          Color(0x00000000),
                          Color(0xE6000000),
                        ],
                        stops: [0.0, 0.22, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // 상단: 이름 · 국기 · PICK · 접속중
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          [
                            item.nickname,
                            if (item.age != null) '${item.age}',
                          ].join(' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // 국기 — 한국은 시안 그림, 그 외는 이모지(이모지는 기기마다 모양이 다름)
                      if (item.flag.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        if (item.country == 'KR')
                          const ArtImage(
                            GardenArt.flagKr,
                            width: 70,
                            height: 71,
                          )
                        else
                          Text(item.flag, style: const TextStyle(fontSize: 20)),
                      ],
                      if (item.pick) ...[
                        const SizedBox(width: 8),
                        const ArtImage(
                          GardenArt.badgePick,
                          width: 144,
                          height: 71,
                        ),
                      ],
                      if (item.online) ...[
                        const SizedBox(width: 8),
                        const _OnlineBadge(),
                      ],
                      const Spacer(),
                      // 잠겨 있어도 **몇 장이 있는지는 보여준다.** 눈금이 1개면 한 장뿐인 줄 알고
                      // 넘겨 볼 생각조차 안 하게 되고, 그러면 등록을 유도하는 장치가 죽는다.
                      if (item.totalPhotos > 1)
                        Row(
                          children: List.generate(item.totalPhotos, (i) {
                            final locked = i >= photos.length;
                            return Container(
                              width: 16,
                              height: 3,
                              margin: const EdgeInsets.only(left: 4),
                              color: Colors.white.withValues(
                                alpha: i == index
                                    ? 0.9
                                    : locked
                                    ? 0.18
                                    : 0.4,
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ),

                // 하단: 한마디(또는 관심사) + 좋아요/댓글/메시지
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showInterests)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final code in item.interests)
                              // 영화만 시안 그림이 있다. 나머지는 기존 칩 —
                              // 관심사 37종 전체 그림을 받으면 코드→에셋 표로 바꾸면 된다.
                              if (code == 'MOVIE')
                                const ArtImage(
                                  GardenArt.interestMovie,
                                  width: 204,
                                  height: 88,
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    ProfileCatalog.interestLabel(
                                      L10n.of(context),
                                      code,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                          ],
                        )
                      else
                        Text(
                          item.intro ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _ArtCount(
                            asset: GardenArt.iconHeart,
                            width: 72,
                            height: 67,
                            label: '${item.likes}',
                            onTap: _like,
                          ),
                          const SizedBox(width: 20),
                          _ArtCount(
                            asset: GardenArt.iconComment,
                            width: 68,
                            height: 71,
                            label: '${item.comments}',
                            onTap: () => showCommentsSheet(context, item),
                          ),
                          const Spacer(),
                          // 대화 신청 — 100자 메시지를 적어 보낸다(기획서 4-3)
                          GestureDetector(
                            onTap: () => _requestChat(item),
                            child: const ArtImage(
                              GardenArt.btnChatRequest,
                              width: 144,
                              height: 145,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 잠긴 사진을 넘기려 했을 때 뜨는 [사진 등록 안내창](기획 4-1).
          // 테두리보다 앞에 둬야 버튼이 눌린다.
          if (_lockNotice)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PhotoLockNotice(
                lockedCount: item.lockedPhotoCount,
                onClose: () => setState(() => _lockNotice = false),
                onGoPost: () {
                  setState(() => _lockNotice = false);
                  ref.read(selectedTabProvider.notifier).state = MainTab.post;
                },
              ),
            ),

          // 카드 테두리 — 클립 **바깥**에 얹어야 모서리가 안 깎인다.
          // 이미지가 아니라 코드로 그린다(이유는 GardenArt.cardBorderWidth 주석).
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GardenArt.cardCornerRadius),
                border: Border.all(
                  color: GardenArt.cardBorderColor,
                  width: GardenArt.cardBorderWidth,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 시안 아이콘 + 숫자. 숫자는 **폰트**라 그대로 두고 아이콘만 그림으로 바꿨다.
/// 잠긴 사진 안내창(기획 4-1). 카드 하단에 얹혀 "왜 안 보이는지"와 "어떻게 열리는지"를 알린다.
///
/// 열쇠는 **상품이 아니라 내 포스트**다 — 그래서 상점이 아니라 포스트 탭으로 보낸다.
class _PhotoLockNotice extends StatelessWidget {
  const _PhotoLockNotice({
    required this.lockedCount,
    required this.onClose,
    required this.onGoPost,
  });

  final int lockedCount;
  final VoidCallback onClose;
  final VoidCallback onGoPost;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLg),
        ),
        border: const Border(top: BorderSide(color: AppColors.moonlight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.moonlight,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.gardenPhotoLockedTitle(lockedCount),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.gardenPhotoLockedBody,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onGoPost,
                  child: Text(l10n.gardenPhotoLockedAction),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ArtCount extends StatelessWidget {
  const _ArtCount({
    required this.asset,
    required this.width,
    required this.height,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final double width;
  final double height;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArtImage(asset, width: width, height: height),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Color(0xFF3FCF6B), size: 8),
          SizedBox(width: 4),
          Text(
            l10n.commonOnline,
            style: TextStyle(color: Color(0xFF3FCF6B), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.pagePad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
