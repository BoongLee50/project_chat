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
import '../../../../shared/widgets/gradient_ring.dart';
import '../../../../shared/widgets/photo_source_sheet.dart';
import '../../../garden/presentation/widgets/garden_art.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../garden/presentation/widgets/comments_sheet.dart';
import '../../../profile/data/models/profile_catalog.dart';
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

    return RefreshIndicator(
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
class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;

    return Row(
      children: [
        Text(
          l10n.homeTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.moonlight,
            shape: BoxShape.circle,
          ),
        ),
        const Spacer(),
        // 프라임이면 배지, 아니면 가입 유도(둘 다 프라임 화면으로 간다).
        _TopPill(
          onTap: () => Navigator.of(context).push(PrimeScreen.route()),
          borderColor: wallet.prime ? AppColors.moonlight : AppColors.border,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium,
                color: wallet.prime ? AppColors.moonlight : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 5),
              Text(
                'Prime',
                style: TextStyle(
                  color: wallet.prime
                      ? AppColors.moonlight
                      : AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 보유 루나 — 누르면 루나상점으로.
        _TopPill(
          onTap: () => Navigator.of(context).push(LunaStoreScreen.route()),
          borderColor: AppColors.moonlight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
              const SizedBox(width: 6),
              Text(
                '${wallet.luna}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({
    required this.child,
    required this.onTap,
    required this.borderColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: borderColor),
        ),
        child: child,
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

            // 좌상단 — 이름·나이·국기·PICK, 그 아래 지역(기획 3-1).
            const Positioned(
              top: 14,
              left: 16,
              right: 120,
              child: _CardIdentity(),
            ),

            // 우상단 — [메인] · 장수 · 삭제.
            if (hasPhoto)
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    // 배지와 버튼을 같은 자리에 둔다 — 둘을 나란히 놓으면 "지금 뭐가 메인인지"와
                    // "누르면 뭐가 되는지"가 헷갈린다.
                    _MainPhotoChip(
                      isMain: _photos[index].id == widget.post.mainPhotoId,
                      onTap: _setMain,
                    ),
                    const SizedBox(width: 8),
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
                    _RoundButton(
                      icon: Icons.delete_outline,
                      background: Colors.black.withValues(alpha: 0.45),
                      iconColor: AppColors.textPrimary,
                      size: 36,
                      onTap: _delete,
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
                  // 촬영 버튼 — 장수를 넘기면 흐려지지만 **눌리기는 한다**.
                  // 아무 반응이 없으면 고장으로 보이므로, 막힌 이유를 알려준다.
                  _RoundButton(
                    icon: Icons.photo_camera_rounded,
                    background: widget.post.canAddPhoto
                        ? AppColors.moonlight
                        : AppColors.surfaceHigh,
                    iconColor: widget.post.canAddPhoto
                        ? Colors.white
                        : AppColors.textMuted,
                    size: 56,
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
        // 꾸미기 외곽선은 클립 **바깥**에 얹어야 모서리가 안 깎인다.
        if (decorated)
          const GradientRing(
            radius: AppDimens.radiusLg,
            width: GardenArt.decoratedBorderWidth,
            colors: GardenArt.decoratedBorderColors,
          ),
      ],
    );
  }
}

/// 카드 좌상단 — 이름·나이·국기·PICK, 그 아래 지역(기획 3-1).
///
/// 값은 전부 **내 프로필**에서 온다. PICK은 부스트를 켰을 때만 뜬다.
class _CardIdentity extends ConsumerWidget {
  const _CardIdentity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final profile = ref.watch(sessionProvider).profile;
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;

    final age = profile?.birthYear == null
        ? null
        : DateTime.now().year - profile!.birthYear!;
    final flag = switch (profile?.country) {
      'KR' => '🇰🇷',
      'JP' => '🇯🇵',
      _ => '',
    };
    final region = (profile?.regions ?? const <String>[]).isEmpty
        ? null
        : ProfileCatalog.regionLabel(l10n, profile!.regions.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                [
                  profile?.nickname ?? '',
                  if (age != null) '$age',
                ].join(' ').trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (flag.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(flag, style: const TextStyle(fontSize: 16)),
            ],
            // 부스트를 켠 동안만 PICK이 붙는다(기획 3-1).
            if (wallet.isBoostOn(StoreKind.postBoost)) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.homePick,
                  style: const TextStyle(
                    color: AppColors.night,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (region != null) ...[
          const SizedBox(height: 2),
          Text(
            region,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ],
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
class _MainPhotoChip extends StatelessWidget {
  const _MainPhotoChip({required this.isMain, required this.onTap});

  final bool isMain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isMain
            ? AppColors.moonlight
            : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.moonlight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMain ? Icons.star_rounded : Icons.star_border_rounded,
            size: 15,
            color: isMain ? AppColors.night : AppColors.moonlight,
          ),
          const SizedBox(width: 4),
          Text(
            isMain ? l10n.homeMainPhoto : l10n.homeSetMainPhoto,
            style: TextStyle(
              color: isMain ? AppColors.night : AppColors.moonlight,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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

    return Row(
      children: [
        Expanded(
          child: _StatusButton(
            icon: Icons.photo_library_outlined,
            label: l10n.homeAlbumPass,
            // 사용 중이면 남은 일수, 아니면 "구매".
            status: passDays == null
                ? l10n.homeBuy
                : l10n.homePassRemainingDays(passDays),
            active: passDays != null,
            accent: AppColors.moonlight,
            onTap: () => Navigator.of(
              context,
            ).push(BoostScreen.route(StoreKind.albumPass)),
          ),
        ),
        const SizedBox(width: AppDimens.gapSm),
        Expanded(
          child: _StatusButton(
            icon: Icons.bolt,
            label: l10n.homeBoost,
            // 사용 중이면 남은 분, 보유만 했으면 "가능", 없으면 "구매".
            status: boost != null
                ? l10n.homeBoostRemaining(boost.remaining.inMinutes + 1)
                : boostStock > 0
                ? l10n.homeBoostReady
                : l10n.homeBuy,
            active: boost != null,
            accent: AppColors.gold,
            onTap: () => Navigator.of(
              context,
            ).push(BoostScreen.route(StoreKind.postBoost)),
          ),
        ),
      ],
    );
  }
}

/// `[아이콘 이름 | 상태]` 한 칸. 상태 칸만 색이 채워진다(시안 3-1).
class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.icon,
    required this.label,
    required this.status,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String status;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? accent : AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: AppColors.night,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
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

class _EmptyPhoto extends ConsumerWidget {
  const _EmptyPhoto();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final nickname = ref.watch(sessionProvider).profile?.nickname ?? '';
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppDimens.pagePad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.nightlight_round,
            color: AppColors.moonlight,
            size: 44,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.homeEmptyGreeting(nickname),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeEmptyHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.size,
    this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: size * 0.5),
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

    // 시안(3-1)에서 이 버튼은 **카드 안 우하단의 작은 노란 버튼**이다.
    // 전체 폭 버튼으로 카드 밖에 두면 화면 구성이 시안과 달라진다.
    return FilledButton(
      onPressed: enabled
          ? () async {
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
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        disabledBackgroundColor: Colors.black.withValues(alpha: 0.4),
        foregroundColor: AppColors.night,
        disabledForegroundColor: AppColors.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: Text(
        post.published ? l10n.homeShareAgain : l10n.homeShare,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }
}
