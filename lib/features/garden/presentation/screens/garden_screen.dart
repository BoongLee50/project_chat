import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../app/main_shell.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../core/util/freshness.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/feed_item.dart';
import '../../../daily/presentation/screens/daily_intro_screen.dart';
import '../../../profile/data/models/profile_catalog.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../../../store/presentation/screens/luna_store_screen.dart';
import '../../../store/presentation/screens/prime_screen.dart';
import '../providers/garden_provider.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/card_frame.dart';
import '../widgets/chat_request_flow.dart';
import '../widgets/garden_art.dart';
import '../widgets/photo_lock.dart';
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
    final scale = DesignCanvas.scaleOf(context);

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
              // 하단 5탭과 **좌우 폭을 맞춘다** — 시안에서 카드·필터·내비가 같은 선(23)에 있다.
              DesignCanvas.contentLeft * scale,
              // 시안 타이틀 위치(y=106).
              DesignCanvas.titleTopInSafeArea(context),
              DesignCanvas.contentLeft * scale,
              // 카드 아래 여백 — 포스트 화면과 **같은 값**이어야 카드 크기가 같다.
              DesignCanvas.cardBottomGap * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타이틀은 시안에서 x=47이라 본문선(23)보다 24만큼 안쪽이다.
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        (GardenArt.titleAt.dx - DesignCanvas.contentLeft) *
                        scale,
                  ),
                  child: const _GardenHeader(),
                ),
                // 머리글 줄 높이는 **Prime 버튼**이 정한다(타이틀보다 크다) — 간격도 거기 기준.
                // 포스트 화면과 **같은 상수**를 써야 두 카드의 시작 위치가 맞는다.
                SizedBox(height: DesignCanvas.headerToRow * scale),
                const _FilterBar(),
                SizedBox(height: GardenArt.filtersToCard * scale),
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
                    // 🚨 **볼 사람이 없으면 배경만 남긴다 — 빈 상태 화면을 만들지 않는다**
                    // (기획 확정 2026-09-19).
                    //
                    // 기획서에 빈 상태가 **처음부터 없다.** 4-1은 대신
                    // *"모든 포스트 사진 풀이 소진 되었을 경우, 다시 반복하여 출력"* 이라
                    // **비는 상황 자체를 상정하지 않는다**(그 반복은 위 서비스가 이미 한다 —
                    // 후보가 바닥나면 스킵·15분 제외를 풀고 다시 채운다).
                    //
                    // 🚨 **그리고 앞으로도 안 만든다 — 빈 자리는 봇 데이터가 채울 예정이다.**
                    // *"유저가 없다면 봇 데이터를 출력"*(기획 2026-09-19). 그래서 안내 문구도
                    // 안내 그림도 요청하지 않았다. 자세한 것과 미리 정해야 할 것은
                    // [09 §4](docs/09-next-task-handoff.md)를 볼 것.
                    //
                    // 📌 `gardenEmptyTitle`/`gardenEmptyDetail` ARB 두 줄이 아직 남아 있지만
                    // **일부러 안 쓴다**(기획서에 없는, 우리가 지어낸 문구였다).
                    // 봇이 늦어져 임시 안내가 필요해지면 되살릴 수 있게 남겨 뒀다.
                    data: (items) => items.isEmpty
                        ? const SizedBox.shrink()
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 타이틀은 **이미지**다(글자가 구워져 있음). 일본어판은 이미지를 교체한다.
        //
        // ⚠️ **Plan_4에서 부제가 빠졌다.** Plan_3 참고용에는 "달빛 아래, 우리의 하루를
        // 나누는 공간"이 있었지만 Plan_4 좌표 시안에는 없다. 실제로 두 줄로 접히면서
        // Prime 버튼 뒤로 넘어가 깨져 보였다. ARB 키(`gardenSubtitle`)는 남겨 둔다 —
        // 기획이 다시 넣자고 하면 자리만 되살리면 된다.
        ArtImage(
          GardenArt.title,
          width: GardenArt.titleSize.width,
          height: GardenArt.titleSize.height,
        ),
        const Spacer(),
        // Prime · 루나상점 진입(시안 577,102 / 838,102)
        GestureDetector(
          onTap: () => Navigator.of(context).push(PrimeScreen.route()),
          child: ArtImage(
            GardenArt.btnPrime,
            width: GardenArt.btnPrimeSize.width,
            height: GardenArt.btnPrimeSize.height,
          ),
        ),
        SizedBox(
          width:
              (GardenArt.btnLunaAt.dx -
                  (GardenArt.btnPrimeAt.dx + GardenArt.btnPrimeSize.width)) *
              DesignCanvas.scaleOf(context),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(LunaStoreScreen.route()),
          // 그림에는 별만 있고 **숫자가 없다.** 시안의 `[★ 80]`처럼 보이려면
          // 보유 루나를 위에 얹어야 한다 — 대화방·친구 머리글은 이미 그렇게 한다.
          // (숫자를 그림에 굽지 않는 편이 옳다. 사람마다 다른 값이다)
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              ArtImage(
                GardenArt.btnLuna,
                width: GardenArt.btnLunaSize.width,
                height: GardenArt.btnLunaSize.height,
              ),
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: _LunaCount(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 가든 머리글의 루나 잔액. 그림 위에 얹는다.
class _LunaCount extends ConsumerWidget {
  const _LunaCount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final luna = ref.watch(walletProvider).valueOrNull?.luna;
    if (luna == null) return const SizedBox.shrink();
    return Text(
      '$luna',
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
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

    // 시안(4-1)의 이 줄은 **네 칸**이다 — 성별·나이·국가 칩 셋 + **[달빛 한마디] 버튼**.
    //
    // ✅ 2026-09-14 전달본부터 **값마다 칩 그림**이 온다(`여자`·`20대`·`한국`).
    // 폰트로 덮어 그리던 방식을 걷어냈다 — 아이콘까지 값에 맞게 바뀌어야 하기 때문이다.
    return LayoutBuilder(
      builder: (context, constraints) {
        // 간격은 시안 좌표에서 나온다(칩 끝 → 다음 칩 시작).
        const gGenderAge = 17.0; // 240 → 257
        const gAgeCountry = 10.0; // 484 → 494
        const gCountryDaily = 13.0; // 711 → 724

        // 🚨 **줄 폭을 상수로 굳히지 말 것.** 예전엔 시안의 1031을 박아 뒀는데,
        // `달빛 한마디` 그림이 330 → 335로 커진 전달본에서 **줄이 1.9px 넘쳐 잘렸다.**
        // 실제로 놓을 것들의 합으로 재면 그림 규격이 또 바뀌어도 저절로 맞는다.
        final designRow =
            GardenArt.filterGenderSize.width +
            gGenderAge +
            GardenArt.filterAgeSize.width +
            gAgeCountry +
            GardenArt.filterCountrySize.width +
            gCountryDaily +
            GardenArt.btnDailyQuestionSize.width;

        final s = constraints.maxWidth / designRow;
        final gapGenderAge = gGenderAge * s;
        final gapAgeCountry = gAgeCountry * s;
        final gapCountryDaily = gCountryDaily * s;

        return Row(
          children: [
            _ArtMenu<String>(
              art: GardenArt.filterGender,
              size: GardenArt.filterGenderSize,
              scale: s,
              // 고르지 않았으면 그림에 구워진 `성별`이 그대로 보인다.
              artByValue: GardenArt.filterGenderByValue,
              options: {
                l10n.commonAll: null,
                l10n.genderFemale: 'FEMALE',
                l10n.genderMale: 'MALE',
              },
              current: filter.gender,
              onPick: controller.selectGender,
            ),
            SizedBox(width: gapGenderAge),
            _ArtMenu<int>(
              art: GardenArt.filterAge,
              size: GardenArt.filterAgeSize,
              scale: s,
              artByValue: GardenArt.filterAgeByValue,
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
            SizedBox(width: gapAgeCountry),
            _ArtMenu<String>(
              art: GardenArt.filterCountry,
              size: GardenArt.filterCountrySize,
              scale: s,
              artByValue: GardenArt.filterCountryByValue,
              options: {
                l10n.commonAll: null,
                l10n.countryKorea: 'KR',
                l10n.countryJapan: 'JP',
              },
              current: filter.country,
              onPick: controller.selectCountry,
            ),
            SizedBox(width: gapCountryDaily),
            // 네 번째 칸 — 드롭다운이 아니라 화면을 바꾸는 버튼이다(기획 4-1 "데일리 참여 이벤트").
            GestureDetector(
              onTap: () => Navigator.of(context).push(DailyIntroScreen.route()),
              child: ArtImage(
                GardenArt.btnDailyQuestion,
                width: GardenArt.btnDailyQuestionSize.width,
                height: GardenArt.btnDailyQuestionSize.height,
                scale: s,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 시안 칩(이미지)을 누르면 드롭다운이 뜬다.
/// **칩은 통째로 이미지, 목록 글자는 ARB** — 이 앱의 UI 언어 두 종류가 한 위젯에 같이 있다.
///
/// ✅ **2026-09-14 전달본부터 값마다 칩 그림이 온다.** 그전에는 라벨 그림 한 장에
/// 고른 값을 **폰트로 덮어 그렸는데**, 이제 `여자`·`20대`·`한국`이 각각 한 장이라
/// **아이콘까지 값에 맞게 바뀐다**(여성 아이콘·태극기). 폰트로는 못 하던 것이다.
///
/// 🚨 **그림이 있는 값만 고를 수 있다.** [artByValue]에 없는 값이 오면 라벨 그림으로
/// 되돌아간다 — 칩이 비어 보이지 않게 하기 위해서다(값을 늘리려면 그림을 먼저 받는다).
class _ArtMenu<T> extends StatelessWidget {
  const _ArtMenu({
    required this.art,
    required this.size,
    required this.scale,
    required this.options,
    required this.current,
    required this.onPick,
    this.artByValue = const {},
  });

  /// 아무것도 고르지 않았을 때의 칩(`성별`·`나이`·`국가`).
  final String art;

  /// 고른 값 → 그 값이 박힌 칩 그림.
  final Map<T, String> artByValue;

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
    final w = size.width * scale;
    final h = size.height * scale;

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
      child: SizedBox(
        width: w,
        height: h,
        // 고른 값의 칩이 있으면 그것을, 없으면 라벨 칩을 그린다.
        child: ArtImage(
          (current == null ? null : artByValue[current as T]) ?? art,
          width: size.width,
          height: size.height,
          scale: scale,
        ),
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
  FeedItem get _item => widget.items.first;

  /// 지금 보고 있는 사진(0부터). **사람이 바뀌면 처음 장으로** 돌아간다([_pageOwner]).
  int _page = 0;
  String? _pageOwner;

  /// 넘길 수 있는 장수 — **잠긴 장도 센다**(2번째부터 흐린 안내 장이 된다).
  int _pageCount(FeedItem item) =>
      item.totalPhotos > item.photoUrls.length
          ? item.totalPhotos
          : item.photoUrls.length;

  /// 사진 넘기기(기획 4-1 "우측 영역 탭은 다음 사진, 좌측 탭은 이전 사진").
  ///
  /// 📌 2026-10-04부터 **팝업 없이 카드에서 바로** 넘긴다. 끝에서 더 누르면 그 자리에 머문다
  /// (돌아 처음으로 가면 몇 장째인지 헷갈린다 — `1/8` 표기가 그대로 위치를 알려 준다).
  void _turnPage(FeedItem item, {required bool forward}) {
    final next = _page + (forward ? 1 : -1);
    if (next < 0 || next >= _pageCount(item)) return;
    setState(() => _page = next);
  }

  /// 볼 수 있는 사진을 미리 받아 둔다 — 누를 때마다 빈 칸이 번쩍이지 않게.
  void _precache(FeedItem item) {
    final headers = ref.read(authHeadersProvider).valueOrNull;
    if (headers == null || headers.isEmpty) return;
    for (final url in item.photoUrls.skip(1)) {
      precacheImage(
        NetworkImage(AuthedImage.absoluteUrl(url), headers: headers),
        context,
      );
    }
  }

  Future<void> _skip() async {
    // Dismissible이 위젯을 제거한 뒤 async가 이어지므로,
    // await 이전에 notifier를 확보해 둔다(dispose 후 ref 사용 방지).
    final notifier = ref.read(feedProvider.notifier);
    final nearlyEmpty = widget.items.length <= 2;

    final error = await notifier.skip(_item);
    if (error != null && mounted) _toast(errorMessage(L10n.of(context), error));
    // 목록이 얼마 안 남으면 다음 페이지를 이어붙인다.
    if (nearlyEmpty) notifier.loadMore();
  }

  Future<void> _like() async {
    final error = await ref.read(feedProvider.notifier).like(_item);
    if (error != null && mounted) _toast(errorMessage(L10n.of(context), error));
  }

  /// 대화 신청 팝업(기획 4-3) — 댓글의 `⋯` 메뉴와 같은 길이다([runChatRequestFlow]).
  Future<void> _requestChat(FeedItem item) =>
      runChatRequestFlow(context, ref, userId: item.userId, onError: _toast);

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final photos = item.photoUrls;
    if (_pageOwner != item.userId) {
      _pageOwner = item.userId;
      _page = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _precache(item);
      });
    }
    // 서버가 준 것보다 뒤의 장은 **잠긴 장**이다(무료 + 오늘 내 포스트 없음 → 메인 1장만 온다).
    final locked = _page >= photos.length;
    final interestArts = [
      for (final code in item.interests) ?GardenArt.interestArt[code],
    ];

    return Dismissible(
      key: ValueKey(item.userId),
      onDismissed: (_) => _skip(),
      child: LayoutBuilder(
        builder: (context, cardBox) => Stack(
          fit: StackFit.expand,
          // 앨범패스 외곽선은 여백만큼 **상자 밖으로** 그린다 — 자르면 다시 안으로 들어간다.
          clipBehavior: Clip.none,
          children: [
            // 사진은 **선 안쪽으로 밀어 넣어** 어떤 경우에도 밖으로 못 나가게 한다.
            Padding(
              padding: EdgeInsets.all(
                CardFrame.photoInset(context, item.decorated),
              ),
              child: ClipRRect(
                // 외곽선 그림의 **실측 곡률**에서 밀어 넣은 만큼 뺀 값.
                // 카드가 세로로 눌린 만큼 자르는 쪽도 같이 눌러야 해 **타원 반경**을 쓴다.
                borderRadius: CardFrame.clipRadius(
                  context,
                  Size(cardBox.maxWidth, cardBox.maxHeight),
                  item.decorated,
                ),
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
                        // **누르고 뗐을 때만** 사진을 넘긴다(`onTapUp` = tap-up). 오른쪽 반은 다음, 왼쪽 반은 이전.
                        // 이 카드의 좌우 스와이프는 **사람을 넘기는 동작**이라, 손가락이 닿자마자
                        // 넘기면 스와이프하려던 손짓이 사진을 넘겨 버린다. 탭 인식기는 손가락이
                        // 조금이라도 밀리면 스스로 물러나므로 두 제스처가 부딪히지 않는다.
                        onTapUp: (d) => _turnPage(
                          item,
                          forward: d.localPosition.dx > cardBox.maxWidth / 2,
                        ),
                        child: locked
                            ? PhotoLockBackdrop(mainPhotoUrl: photos.first)
                            : AuthedImage(url: photos[_page]),
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

                    // 잠긴 장(2번째부터)이면 안내 + [새 사진 등록하기]. 이름·좋아요 줄은 그대로 위에 남는다.
                    if (locked && photos.isNotEmpty) const PhotoLockGuide(),

                    // 상단: 이름 · 국기 · PICK · 접속중 (+ 아래 줄에 활동 지역)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // ⚠️ 이름 쪽을 **Expanded 한 덩어리**로 묶어야 장수 표기가 오른쪽 끝에 붙는다.
                              // 전에는 `Flexible(이름) … Spacer() … 1/8`이었는데 Flexible과 Spacer가
                              // 남는 폭을 **반씩 나눠 가져** 장수가 가운데쯤에 떠 있었다.
                              Expanded(
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
                                    // 국기 — 한·일은 시안 그림(2026-09-14에 일장기도 받았다).
                                    // 그 밖의 나라는 이모지로 둔다(기기마다 모양이 다르지만 그림이 없다).
                                    if (item.flag.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      if (GardenArt.flagOf(item.country)
                                          case final flag?)
                                        ArtImage(
                                          flag,
                                          width: GardenArt.flagSize.width,
                                          height: GardenArt.flagSize.height,
                                        )
                                      else
                                        Text(
                                          item.flag,
                                          style: const TextStyle(fontSize: 20),
                                        ),
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
                                  ],
                                ),
                              ),
                              // 시안(4-1)은 눈금이 아니라 **`1/8` 같은 숫자 표기**다 — 지금 몇 장째 / 전체.
                              //
                              // **잠겨 있어도 전체 장수는 알린다** — 몇 장이 더 있는지 보여야
                              // 눌러 볼 마음이 생기고, 그게 사진 등록을 유도하는 장치다.
                              if (_pageCount(item) > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_page + 1}/${_pageCount(item)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // 활동 지역(기획 §2-5) — 있는 사람만. 코드는 서버가, 문구는 여기서.
                          // 핀 아이콘 없이 **흰 글자만**, 이름 아래 한 줄(기획 수정 2026-10-04).
                          if (item.region != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                ProfileCatalog.regionLabel(
                                  L10n.of(context),
                                  item.region!,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
                          // 관심사 — **그림이 있는 것만** 보인다(기획 수정 2026-10-04).
                          // 그림이 온 건 아직 `영화` 한 장이라 대부분의 카드는 이 줄이 비어 있다.
                          // 그림이 오면 `GardenArt.interestArt`에 한 줄 넣으면 저절로 나타난다.
                          //
                          // 🚫 **자기소개는 카드에 띄우지 않는다**(기획 수정 2026-10-04 — 길어질 수 있게
                          // 바뀌어서). 전에는 관심사가 없으면 그 자리에 소개를 썼다.
                          // 소개는 [포스트 정보]에서 본다.
                          if (interestArts.isNotEmpty) ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final art in interestArts)
                                  ArtImage(
                                    art,
                                    width: GardenArt.interestSize.width,
                                    height: GardenArt.interestSize.height,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              _ArtCount(
                                asset: GardenArt.iconHeart,
                                width: 72,
                                height: 67,
                                label: '${item.likes}',
                                // 하루 한 번 — 이미 눌렀으면 흐려지고 다시 눌러도 늘지 않는다.
                                done: item.likedByMe,
                                onTap: _like,
                              ),
                              const SizedBox(width: 20),
                              _ArtCount(
                                asset: GardenArt.iconComment,
                                width: GardenArt.iconCommentSize.width,
                                height: GardenArt.iconCommentSize.height,
                                label: '${item.comments}',
                                onTap: () =>
                                    showPostCommentsSheet(context, item),
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
            ),

            // 카드 외곽선 — 클립 **바깥**에 얹어야 모서리가 안 깎인다.
            // 앨범 패스·프라임을 가진 사람의 포스트는 **무지개빛**이다(기획 화면 26·29).
            CardFrame(decorated: item.decorated),
          ],
        ),
      ),
    );
  }
}

/// 시안 아이콘 + 숫자. 숫자는 **폰트**라 그대로 두고 아이콘만 그림으로 바꿨다.
class _ArtCount extends StatelessWidget {
  const _ArtCount({
    required this.asset,
    required this.width,
    required this.height,
    required this.label,
    required this.onTap,
    this.done = false,
  });

  final String asset;
  final double width;
  final double height;
  final String label;
  final VoidCallback onTap;

  /// 이미 누른 상태(좋아요). **하루 한 번**이라 다시 눌러도 소용없다는 걸 흐리게 알린다 —
  /// 눌리는데 아무 일도 안 일어나면 고장으로 읽힌다.
  final bool done;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 이미지는 자기를 히트테스트하지 않는다(함정 #38).
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: done ? 0.55 : 1.0,
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
