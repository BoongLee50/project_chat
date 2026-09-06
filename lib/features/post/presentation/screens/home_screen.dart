import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../../shared/widgets/gradient_ring.dart';
import '../../../../shared/widgets/photo_source_sheet.dart';
import '../widgets/post_art.dart';
import '../../../garden/presentation/widgets/garden_art.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../garden/presentation/widgets/comments_sheet.dart';
import '../../../store/data/models/store_models.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../../../store/presentation/screens/boost_screen.dart';
import '../../../store/presentation/screens/luna_store_screen.dart';
import '../../../store/presentation/screens/prime_screen.dart';
import '../../data/models/my_post.dart';
import '../providers/post_provider.dart';

/// 홈 — 오늘의 포스트. 메인 셸의 '포스트' 탭 본문. (기획서 3장, 01 문서 §1.3)
///
/// 사진 등록/삭제·메인 지정·공유하기를 서버와 연동한다.
///
/// 시안(3-1)의 구성은 셋뿐이다 — **상단 바 / 패스·부스트 두 버튼 / 포스트 카드**.
/// 이름·지역·PICK·좋아요·댓글·[포스트 공유하기]는 전부 **카드 안에 얹힌다.**
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final postState = ref.watch(myPostProvider);

    // 앨범 패스를 사면 등록 규칙(사진 장수·시간 제한)이 달라진다. 서버가 판정하므로
    // 패스 보유 여부가 바뀐 순간 포스트 상태를 다시 읽어야 화면이 따라온다.
    ref.listen(walletProvider, (previous, next) {
      final before = previous?.valueOrNull?.has(StoreKind.albumPass);
      final after = next.valueOrNull?.has(StoreKind.albumPass);
      if (before != null && after != null && before != after) {
        ref.read(myPostProvider.notifier).refresh();
      }
    });

    // 시안 배경(밤 풍경) — 달빛가든과 같은 방식으로 **상태바 뒤까지** 올린다.
    // SafeArea 안에서는 padding·viewPadding이 둘 다 깎여 상태바 높이를 알 수 없으므로
    // 화면(View)에서 직접 읽는다(함정 #32).
    final statusBar = MediaQueryData.fromView(View.of(context)).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      // ⚠️ `expand`가 없으면 Stack이 **느슨한 제약**을 주고, 그 안의 SingleChildScrollView가
      // **내용 높이만큼만 줄어든다** — 본문이 위로 뭉치고 하단 내비가 화면 중간에 뜬다.
      // (달빛가든은 Column+Expanded라 느슨해도 채워져서 이 문제가 안 보였다)
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -statusBar,
          left: 0,
          right: 0,
          child: Image.asset(
            PostArt.background,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
          ),
        ),
        RefreshIndicator(
      color: AppColors.moonlight,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(myPostProvider.notifier).refresh(),
      child: postState.when(
        loading: () => const _CenteredScroll(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (error, _) => _CenteredScroll(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.pagePad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: AppColors.textMuted,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.homeLoadFailed,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.homePullToRefresh,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (post) => _PostBody(post: post),
      ),
        ),
      ],
    );
  }
}

/// RefreshIndicator가 동작하려면 항상 스크롤 가능해야 한다.
class _CenteredScroll extends StatelessWidget {
  const _CenteredScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _PostBody extends ConsumerWidget {
  const _PostBody({required this.post});

  final MyPost post;

  /// 카드 위에 놓이는 것들(상단 바 + 두 버튼 + 사이 여백)의 높이.
  /// 카드가 **남은 공간을 채우도록** 하려고 빼 준다 — 시안에서 카드는 화면을 거의 채운다.
  static const double _aboveCard = 132;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 시안(3-1)의 세로 구성은 셋뿐이다 — 상단 바 / 패스·부스트 두 버튼 / 포스트 카드.
    // 이름·좋아요·공유 버튼은 **카드 안**에 얹힌다.
    //
    // ⚠️ "오늘의 달" 카드는 시안에도 3-1 본문에도 없어 걷어냈다(Plan_2 잔재).
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePad,
          AppDimens.gapMd,
          AppDimens.pagePad,
          AppDimens.gapMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopBar(),
            const SizedBox(height: AppDimens.gapMd),
            const _PassBoostRow(),
            const SizedBox(height: AppDimens.gapMd),
            SizedBox(
              // 작은 기기에서 카드가 찌그러지지 않게 최소 높이를 둔다.
              height: (constraints.maxHeight - _aboveCard).clamp(320.0, 1200.0),
              child: _PostPhotoCard(post: post),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 상단 바 ──────────────────────────────────────────────
/// 타이틀 · Prime · 루나상점. **셋 다 그림이다**(Plan_4).
///
/// 달빛가든 머리글과 **같은 자리·같은 그림**을 쓴다(시안에서 두 화면의 상단이 동일하다) —
/// 그래서 Prime·루나 버튼은 `assets/images/common/`에 두고 양쪽이 공유한다.
class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ArtImage(
          PostArt.title,
          width: PostArt.titleSize.width,
          height: PostArt.titleSize.height,
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).push(PrimeScreen.route()),
          child: ArtImage(
            PostArt.btnPrime,
            width: PostArt.btnPrimeSize.width,
            height: PostArt.btnPrimeSize.height,
          ),
        ),
        SizedBox(
          width:
              (PostArt.btnLunaAt.dx -
                      (PostArt.btnPrimeAt.dx + PostArt.btnPrimeSize.width)) *
                  DesignCanvas.scaleOf(context),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(LunaStoreScreen.route()),
          // 그림에는 별만 있고 **숫자가 없다** — 사람마다 다른 값이라 굽지 않는 게 옳다.
          // 보유 루나를 위에 얹는다(달빛가든 머리글과 같은 방식).
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              ArtImage(
                PostArt.btnLuna,
                width: PostArt.btnLunaSize.width,
                height: PostArt.btnLunaSize.height,
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

/// 상단 바의 루나 잔액. 그림 위에 얹는다.
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

// ── 포스트 사진 카드 ─────────────────────────────────────
class _PostPhotoCard extends ConsumerStatefulWidget {
  const _PostPhotoCard({required this.post});

  final MyPost post;

  @override
  ConsumerState<_PostPhotoCard> createState() => _PostPhotoCardState();
}

class _PostPhotoCardState extends ConsumerState<_PostPhotoCard> {
  int _index = 0;
  bool _busy = false;

  List<PostPhoto> get _photos => widget.post.photos;

  /// 사진 버튼. 올릴 수 있으면 선택 시트를 열고, 막혀 있으면 **왜 막혔는지** 알려준다.
  ///
  /// 서버가 쓰는 오류 코드를 그대로 재사용하므로 문구가 한 곳(ARB)에서 관리되고
  /// 일본어도 자동으로 따라온다.
  Future<void> _captureOrExplain() async {
    final reason = widget.post.addPhotoBlockedReason;
    if (reason == null) return _pick();

    _toast(
      errorMessage(
        L10n.of(context),
        // 서버가 막았을 때와 같은 문장을 만들려면 숫자도 같은 자리(field)에 넣어야 한다.
        ApiException(
          message: '',
          code: reason,
          field: '${widget.post.maxPhotos}',
        ),
      ),
    );
  }

  /// 앨범·촬영 중에 고르게 한다. 포스트는 **앨범이 앨범 패스 전용**이라(기획서 3-1)
  /// 패스가 없으면 줄을 죽이고 이유를 적어 둔다 — 없는 척 숨기면 상품이 있는 줄도 모른다.
  /// (프로필 사진에는 이 제한이 없어 시트가 조건만 다르게 받는다)
  Future<void> _pick() async {
    if (_busy) return;
    final l10n = L10n.of(context);
    // Plan_3 §3-1: 카메라 촬영과 갤러리 선택 모두 가능(무료·유료 구분 없음).
    const canUseGallery = true;

    final choice = await PhotoSourceSheet.show(
      context,
      title: l10n.photoSheetPostTitle,
      subtitle: l10n.photoSheetPostSubtitle,
      galleryEnabled: canUseGallery,
      galleryHint: l10n.photoSourceGalleryPassOnly,
    );
    if (choice == null || !mounted) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: choice == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _busy = true);
    final bytes = await file.readAsBytes();
    final error = await ref.read(myPostProvider.notifier).addPhoto(bytes);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) _toast(errorMessage(L10n.of(context), error));
  }

  Future<void> _delete() async {
    if (_busy || _photos.isEmpty) return;
    // Plan_4에서 확인 팝업이 생겼다 — 사진 삭제는 되돌릴 수 없다.
    final ok = await ConfirmDialog.show(
      context,
      L10n.of(context).homeDeletePhotoConfirm,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final target = _photos[_index.clamp(0, _photos.length - 1)];
    final error = await ref
        .read(myPostProvider.notifier)
        .deletePhoto(target.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _index = 0;
    });
    if (error != null) _toast(errorMessage(L10n.of(context), error));
  }

  /// 보고 있는 사진을 대표 사진으로 세운다(달빛가든에 이 사진이 나간다).
  Future<void> _setMain() async {
    if (_busy || _photos.isEmpty) return;
    setState(() => _busy = true);
    final target = _photos[_index.clamp(0, _photos.length - 1)];
    final error = await ref
        .read(myPostProvider.notifier)
        .setMainPhoto(target.id);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(
      error != null
          ? errorMessage(L10n.of(context), error)
          : L10n.of(context).homeMainPhotoSet,
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final headers = ref.watch(authHeadersProvider).valueOrNull ?? const {};
    final hasPhoto = _photos.isNotEmpty;
    // 사진이 없으면 clamp 상한이 -1이 되어 ArgumentError가 난다.
    // index는 hasPhoto인 가지에서만 쓰이므로 빈 경우엔 0으로 둔다.
    final index = hasPhoto ? _index.clamp(0, _photos.length - 1) : 0;

    // 시안(3-1)은 **모든 것이 사진 위에 얹힌 한 장**이다 — 이름·지역·PICK은 좌상단,
    // [메인]·장수·삭제는 우상단, 좋아요·댓글은 좌하단, [포스트 공유하기]는 우하단.
    // 카드 바깥에 줄을 따로 두면 시안과 다른 화면이 된다.
    // 앨범 패스·프라임을 가지고 있으면 **내 포스트에도** 꾸미기 외곽선이 붙는다
    // (기획 화면 26·29). 산 사람이 자기 화면에서 먼저 확인할 수 있어야 한다.
    final wallet = ref.watch(walletProvider).valueOrNull;
    final decorated =
        wallet != null && (wallet.prime || wallet.has(StoreKind.albumPass));

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              // 좌/우 탭으로 등록된 사진을 순차 검색(기획서 3-1).
              // ⚠️ **내 포스트는 달빛가든과 다르다** — 가든 카드는 좌우 스와이프가 "사람"이라
              // 사진 넘기기를 창으로 뺐지만, 여기는 겹치는 제스처가 없어 탭으로 넘긴다.
              GestureDetector(
                // Image는 자기 자신을 히트테스트하지 않아 기본값(deferToChild)으로는
                // 탭이 안 들어온다 — 좌우로 넘겨 보는 기능이 조용히 죽는다(함정 #38).
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final width = context.size?.width ?? 1;
                  final next = details.localPosition.dx > width / 2
                      ? index + 1
                      : index - 1;
                  setState(() => _index = next.clamp(0, _photos.length - 1));
                },
                child: _AuthedImage(url: _photos[index].url, headers: headers),
              )
            else
              const _EmptyPhoto(),

            // 가독성 스크림 — 위아래 글자가 사진에 묻히지 않게.
            // ⚠️ IgnorePointer가 없으면 아래 사진의 탭을 전부 먹는다(함정 #38).
            if (hasPhoto)
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xB3000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0xCC000000),
                      ],
                      stops: [0.0, 0.25, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

            if (_busy)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  color: AppColors.moonlight,
                ),
              ),

            // 좌상단 — `[TOP]` `[PICK]`.
            //
            // ⚠️ **Plan_4에서 이름·나이·지역이 빠졌다.** 좌표 시안과 완성 화면 둘 다
            // 이 자리에 [TOP]과 PICK만 둔다. 내 포스트 화면에서 내 이름을 다시 보여줄
            // 이유가 없다 — 이름이 필요한 건 남을 보는 달빛가든 카드 쪽이다.
            if (hasPhoto)
              Positioned(
                top: 12,
                left: 14,
                child: Row(
                  children: [
                    _MainPhotoChip(
                      isMain: _photos[index].id == widget.post.mainPhotoId,
                      onTap: _setMain,
                    ),
                    const SizedBox(width: 10),
                    // 부스트를 켠 동안만 PICK이 붙는다(기획 3-1).
                    const _PickBadge(),
                  ],
                ),
              ),

            // 우상단 — 장수 · 삭제.
            if (hasPhoto)
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    // 시안은 눈금이 아니라 `1/9` **숫자 표기**다.
                    Text(
                      '${index + 1}/${widget.post.maxPhotos}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _delete,
                      child: ArtImage(
                        PostArt.btnDelete,
                        width: PostArt.btnDeleteSize.width,
                        height: PostArt.btnDeleteSize.height,
                      ),
                    ),
                  ],
                ),
              ),

            // 하단 한 줄 — 좋아요·댓글 / 촬영 / 공유하기(시안 3-1).
            //
            // 셋을 각각 Positioned로 두면 글자가 길어질 때 **서로 겹친다**
            // (실제로 "공유됨 · 다시 공유하기"가 촬영 버튼을 가렸다).
            // 한 Row에 넣어 자리를 나눠 갖게 한다.
            Positioned(
              left: 14,
              right: 14,
              bottom: 18,
              child: Row(
                children: [
                  // 댓글을 누르면 [포스트 댓글]이 뜬다(기획 3-1).
                  _CardCounts(post: widget.post),
                  const Spacer(),
                  // 촬영 버튼 — 그림으로 오지 않아 코드로 그린다(무지개 링 + 흰 카메라).
                  // 장수를 넘기면 흐려지지만 **눌리기는 한다**. 아무 반응이 없으면
                  // 고장으로 보이므로, 막힌 이유를 알려준다.
                  _CameraButton(
                    enabled: widget.post.canAddPhoto,
                    onTap: _captureOrExplain,
                  ),
                  const Spacer(),
                  Flexible(flex: 0, child: _ShareButton(post: widget.post)),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
        // 카드 외곽선은 클립 **바깥**에 얹어야 모서리가 안 깎인다.
        // 그림 대신 코드로 그린다(이유는 GardenArt.cardBorderWidth 주석).
        //
        // **달빛가든 카드와 같은 값**을 쓴다: 산 사람이 자기 화면에서 먼저 확인할 수
        // 있어야 하고, 남에게 보이는 모습과 달라서도 안 된다(기획 화면 26·29).
        if (decorated)
          const GradientRing(
            radius: GardenArt.cardCornerRadius,
            width: GardenArt.decoratedBorderWidth,
            colors: GardenArt.decoratedBorderColors,
          )
        else
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  GardenArt.cardCornerRadius,
                ),
                border: Border.all(
                  color: GardenArt.cardBorderColor,
                  width: GardenArt.cardBorderWidth,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 부스트를 켠 동안만 붙는 PICK 배지(기획 3-1). Plan_4에서 그림으로 왔다.
///
/// 달빛가든 카드의 PICK과 **같은 그림**이라 `common/`에 둔다 — 내 화면과 남의 화면에서
/// 다르게 보이면 "내가 산 게 저렇게 나가는구나"를 확인할 수 없다.
class _PickBadge extends ConsumerWidget {
  const _PickBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider).valueOrNull;
    if (wallet == null || !wallet.isBoostOn(StoreKind.postBoost)) {
      return const SizedBox.shrink();
    }
    return ArtImage(
      PostArt.badgePick,
      width: PostArt.badgePickSize.width,
      height: PostArt.badgePickSize.height,
    );
  }
}

/// 카드 좌하단 — 달빛가든에서 받은 좋아요·댓글(기획 3-1, "사진 종류와 상관없음").
class _CardCounts extends ConsumerWidget {
  const _CardCounts({required this.post});

  final MyPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(sessionProvider).profile;

    return Row(
      children: [
        const Icon(Icons.favorite, color: AppColors.danger, size: 20),
        const SizedBox(width: 6),
        Text('${post.likes}', style: _countStyle),
        const SizedBox(width: 16),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          // [댓글] 버튼 → [포스트 댓글] 화면(기획 3-1). 내 포스트라 대상도 나다.
          onTap: profile == null
              ? null
              : () => showCommentsSheet(
                  context,
                  kind: CommentTargetKind.post,
                  targetId: profile.id,
                  ownerId: profile.id,
                  title: L10n.of(context).commentsTitle(profile.nickname ?? ''),
                ),
          child: Row(
            children: [
              const Icon(
                Icons.mode_comment_outlined,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 6),
              Text('${post.comments}', style: _countStyle),
            ],
          ),
        ),
      ],
    );
  }

  static const _countStyle = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
}

/// 대표 사진 표시 겸 지정 버튼(Plan_3 §3-1 `[메인]`).
///
/// 메인이면 **채워진 배지**로 상태만 보여주고 누를 수 없다 — 이미 메인인 걸 다시 눌러 봐야
/// 아무 일도 안 일어나는데, 눌리면 고장으로 읽힌다.
/// 달빛가든에 나갈 대표 사진을 지정하는 버튼. **Plan_4에서 `[메인]` → `[TOP]`** 으로 바뀌었고
/// 그림도 함께 왔다(선택/비선택 두 벌).
///
/// 이미 TOP이면 누를 게 없으므로 탭을 걸지 않는다 — 눌러도 같은 상태가 되는 버튼은
/// "반응이 없다"로 보인다.
class _MainPhotoChip extends StatelessWidget {
  const _MainPhotoChip({required this.isMain, required this.onTap});

  final bool isMain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Semantics(
      label: L10n.of(context).homeSetMainPhoto,
      button: !isMain,
      selected: isMain,
      child: ArtImage(
        isMain ? PostArt.btnTopOn : PostArt.btnTopOff,
        width: PostArt.btnTopSize.width,
        height: PostArt.btnTopSize.height,
      ),
    );

    return isMain ? chip : GestureDetector(onTap: onTap, child: chip);
  }
}

/// 상단 두 버튼 — `[포스트 앨범 패스 | 상태]` `[⚡ 부스트 | 상태]` (기획 3-1).
///
/// 둘 다 **상태에 따라 오른쪽 라벨만 바뀐다**:
/// - 앨범 패스: 미구매 `구매` / 사용 중 `4일`
/// - 부스트: 미구매 `구매` / 보유했지만 미사용 `가능` / 사용 중 `45분`
///
/// 라벨을 상태로 쓰지 않고 **지갑 상태에서 매번 계산**한다 — 문구는 언어를 타므로
/// 상태 판정의 기준이 될 수 없다(함정 #25).
class _PassBoostRow extends ConsumerStatefulWidget {
  const _PassBoostRow();

  @override
  ConsumerState<_PassBoostRow> createState() => _PassBoostRowState();
}

class _PassBoostRowState extends ConsumerState<_PassBoostRow> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 부스트 남은 시간이 흘러가는 걸 보여준다. 켜진 부스트가 없으면 굳이 다시 그리지 않는다.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final wallet = ref.read(walletProvider).valueOrNull;
      if (wallet != null && wallet.activeBoosts.isNotEmpty) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;

    final passDays = wallet.remainingDays(StoreKind.albumPass);
    final boost = wallet.activeBoost(StoreKind.postBoost);
    final boostStock = wallet.stockOf(StoreKind.postBoost);

    // 시안에서 이 줄은 x=23에서 시작해 x=1052에서 끝난다 → 폭 1029.
    return LayoutBuilder(
      builder: (context, constraints) {
        final designRow =
            PostArt.btnBoostAt.dx +
            PostArt.btnBoostSize.width -
            DesignCanvas.contentLeft;
        final s = constraints.maxWidth / designRow;
        final gap =
            (PostArt.btnBoostAt.dx -
                    (PostArt.btnAlbumPassAt.dx +
                        PostArt.btnAlbumPassSize.width)) *
                s;

        return Row(
          children: [
            _ArtStatusButton(
              art: PostArt.btnAlbumPass,
              size: PostArt.btnAlbumPassSize,
              statusLeft: PostArt.btnAlbumPassStatusLeft,
              scale: s,
              // 사용 중이면 남은 일수, 아니면 "구매".
              status: passDays == null
                  ? l10n.homeBuy
                  : l10n.homePassRemainingDays(passDays),
              accent: passDays != null ? AppColors.moonlight : AppColors.textSecondary,
              onTap: () => Navigator.of(
                context,
              ).push(BoostScreen.route(StoreKind.albumPass)),
            ),
            SizedBox(width: gap),
            _ArtStatusButton(
              art: PostArt.btnBoost,
              size: PostArt.btnBoostSize,
              statusLeft: PostArt.btnBoostStatusLeft,
              scale: s,
              // 사용 중이면 남은 분, 보유만 했으면 "가능", 없으면 "구매".
              status: boost != null
                  ? l10n.homeBoostRemaining(boost.remaining.inMinutes + 1)
                  : boostStock > 0
                  ? l10n.homeBoostReady
                  : l10n.homeBuy,
              accent: boost != null ? AppColors.gold : AppColors.textSecondary,
              onTap: () => Navigator.of(
                context,
              ).push(BoostScreen.route(StoreKind.postBoost)),
            ),
          ],
        );
      },
    );
  }
}

/// 그림 버튼 + **막대 오른쪽에 얹는 상태값**.
///
/// 그림에는 `포스트 앨범 |` 까지만 있고 그 뒤는 비어 있다.
/// 남은 일수·남은 분은 사람마다 다르므로 폰트로 그린다(이 앱 UI 언어의 첫 번째 종류).
class _ArtStatusButton extends StatelessWidget {
  const _ArtStatusButton({
    required this.art,
    required this.size,
    required this.statusLeft,
    required this.scale,
    required this.status,
    required this.accent,
    required this.onTap,
  });

  final String art;
  final Size size;

  /// 그림에서 상태값이 들어갈 자리의 왼쪽(시안 원본 픽셀).
  final double statusLeft;
  final double scale;
  final String status;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size.width * scale,
        height: size.height * scale,
        child: Stack(
          children: [
            ArtImage(art, width: size.width, height: size.height, scale: scale),
            Positioned(
              left: statusLeft * scale,
              right: 16 * scale,
              top: 0,
              bottom: 0,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    status,
                    maxLines: 1,
                    style: TextStyle(
                      color: accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 인증이 필요한 이미지(`GET /files?key=`) 로더.
class _AuthedImage extends StatelessWidget {
  const _AuthedImage({required this.url, required this.headers});

  final String url;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    if (headers.isEmpty) {
      return const ColoredBox(color: AppColors.surface);
    }
    return Image.network(
      _absolute(url),
      fit: BoxFit.cover,
      headers: headers,
      errorBuilder: (_, _, _) => const _EmptyPhoto(),
    );
  }

  /// 서버는 상대 경로(`/files?key=...`)를 주므로 base URL을 붙인다.
  static String _absolute(String url) {
    if (url.startsWith('http')) return url;
    return '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080')}$url';
  }
}

/// 사진을 아직 안 올렸을 때 카드를 채우는 그림(Plan_4 `배경_등록 사진 없을때`).
///
/// **안내 문구가 그림 안에 있다** — 그래서 여기에 글자를 따로 그리지 않는다.
/// 겹쳐 그리면 같은 말이 두 번 나온다(실제로 한 번 그렇게 나왔다).
///
/// 🚨 **받은 그림은 일본어판뿐이다.** 한국어로 앱을 켜도 이 안내만 일본어로 남는다.
/// 코드로는 못 고친다 — **한국어판(또는 글자 없는 판)을 받아야 한다.**
/// `login_bg.jpg`와 같은 종류의 리소스 결함이고 docs/08에 적어 두었다.
class _EmptyPhoto extends StatelessWidget {
  const _EmptyPhoto();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      PostArt.emptyBackground,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// 촬영 버튼 — 시안 `441, 1838` 자리의 무지개 링 + 흰 카메라.
///
/// **그림으로 오지 않은 몇 안 되는 요소다.** 원형 그러데이션 테두리는 코드로 정확히
/// 그려지고 크기를 바꿔도 안 뭉개져서, 그림보다 코드가 낫다(함정 #31과 같은 판단).
class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = PostArt.cameraSize * DesignCanvas.scaleOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        // 막혀도 **누를 수는 있게** 둔다 — 흐리게만 해서 "지금은 안 된다"를 보인다.
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: d,
          height: d,
          padding: EdgeInsets.all(d * 0.07),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: PostArt.cameraRing),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF12101F),
            ),
            child: Icon(
              Icons.photo_camera_rounded,
              color: Colors.white,
              size: d * 0.44,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareButton extends ConsumerWidget {
  const _ShareButton({required this.post});

  final MyPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final enabled = post.photos.isNotEmpty;

    // 시안(3-1)에서 이 버튼은 **카드 안 우하단**이고, Plan_4에서 그림으로 왔다.
    // 글자(`포스트 공유하기`)가 그림 안에 있으므로 일본어판은 이미지를 교체한다.
    return GestureDetector(
      onTap: enabled
          ? () async {
              // Plan_4에서 확인 팝업이 생겼다.
              final ok = await ConfirmDialog.show(
                context,
                l10n.homeSharePostConfirm,
              );
              if (!ok || !context.mounted) return;

              final error = await ref.read(myPostProvider.notifier).publish();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      error == null
                          ? l10n.homeShared
                          : errorMessage(l10n, error),
                    ),
                  ),
                );
            }
          : null,
      child: Opacity(
        // 사진이 없으면 공유할 것이 없다. 죽이지 않고 흐리게만 둔다.
        opacity: enabled ? 1 : 0.45,
        child: Semantics(
          label: post.published ? l10n.homeShareAgain : l10n.homeShare,
          button: true,
          child: ArtImage(
            PostArt.btnShare,
            width: PostArt.btnShareSize.width,
            height: PostArt.btnShareSize.height,
          ),
        ),
      ),
    );
  }
}
