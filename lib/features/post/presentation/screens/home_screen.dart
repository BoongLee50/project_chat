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
import '../../../../shared/widgets/gate_notice.dart';
import '../../../../shared/widgets/photo_source_sheet.dart';
import '../../../auth/presentation/providers/gate_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../store/data/models/store_models.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../../../store/presentation/screens/boost_screen.dart';
import '../../../store/presentation/screens/luna_store_screen.dart';
import '../../../store/presentation/screens/prime_screen.dart';
import '../../data/models/my_post.dart';
import '../providers/post_provider.dart';

/// 홈 — 오늘의 포스트. 메인 셸의 '포스트' 탭 본문. (기획서 3장, 01 문서 §1.3)
///
/// 사진 등록/삭제, 하루 한 마디, 공유하기를 서버와 연동한다.
/// 상단 Prime 배지·루나 잔액과 앨범패스 배지·부스트 버튼은 store 도메인(지갑) 기준.
/// 달 위상·좋아요/댓글 수치는 아직 미연결.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    return SingleChildScrollView(
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
          // 운영시간 밖에는 사진 등록·공유만 막힌다(하루 한 마디는 언제든 가능).
          if (!ref.watch(gateOpenProvider))
            GateBanner(message: l10n.homeGateClosed),
          _InfoCards(post: post),
          const SizedBox(height: AppDimens.gapMd),
          _PostPhotoCard(post: post),
          const SizedBox(height: AppDimens.gapMd),
          const _NameLikeRow(),
          const SizedBox(height: AppDimens.gapMd),
          const _BoostRow(),
          const SizedBox(height: AppDimens.gapLg),
          _OneLiner(post: post),
          const SizedBox(height: AppDimens.gapLg),
          _ShareButton(post: post),
        ],
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

// ── 달 정보 / 남은 시간 카드 ─────────────────────────────
class _InfoCards extends StatelessWidget {
  const _InfoCards({required this.post});

  final MyPost post;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            child: Row(
              children: [
                Icon(Icons.nightlight_round, color: AppColors.gold, size: 30),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.homeTodayMoon,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    // 달 위상은 별도 이벤트 테이블 예정(기획서 3-1).
                    Text(
                      l10n.homeMoonCrescent,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimens.gapMd),
        Expanded(
          child: _InfoCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.homeUploadRemaining,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _remainingLabel(post),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 프라임/앨범패스는 시간 제한이 없어 "PASS"로 표시한다(기획서 3-1).
  static String _remainingLabel(MyPost post) {
    if (post.uploadUnlimited) return 'PASS';
    if (!post.gateOpen) return '--:--';
    final seconds = post.remainingUploadSeconds ?? 0;
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.moonlight.withValues(alpha: 0.6)),
      ),
      child: child,
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
        ApiException(message: '', code: reason),
      ),
    );
  }

  /// 앨범·촬영 중에 고르게 한다. 포스트는 **앨범이 앨범 패스 전용**이라(기획서 3-1)
  /// 패스가 없으면 줄을 죽이고 이유를 적어 둔다 — 없는 척 숨기면 상품이 있는 줄도 모른다.
  /// (프로필 사진에는 이 제한이 없어 시트가 조건만 다르게 받는다)
  Future<void> _pick() async {
    if (_busy) return;
    final l10n = L10n.of(context);
    final canUseGallery = widget.post.uploadUnlimited;

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
    final error = await ref.read(myPostProvider.notifier).deletePhoto(target.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _index = 0;
    });
    if (error != null) _toast(errorMessage(L10n.of(context), error));
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: AspectRatio(
        aspectRatio: 0.86,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              // 좌/우 탭으로 등록된 사진을 순차 검색(기획서 3-1).
              GestureDetector(
                onTapUp: (details) {
                  final width = context.size?.width ?? 1;
                  final next = details.localPosition.dx > width / 2
                      ? index + 1
                      : index - 1;
                  setState(
                    () => _index = next.clamp(0, _photos.length - 1),
                  );
                },
                child: _AuthedImage(
                  url: _photos[index].url,
                  headers: headers,
                ),
              )
            else
              const _EmptyPhoto(),

            if (_busy)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  color: AppColors.moonlight,
                ),
              ),

            // 앨범 패스 배지 — 보유 중일 때만. 남은 기간과 등록 가능 장수를 알려준다.
            Consumer(
              builder: (context, ref, _) {
                final wallet =
                    ref.watch(walletProvider).valueOrNull ?? Wallet.empty;
                if (!wallet.has(StoreKind.albumPass)) {
                  return const SizedBox.shrink();
                }
                final days = wallet.remainingDays(StoreKind.albumPass);
                return Positioned(
                  right: 12,
                  top: 12,
                  child: _AlbumPassBadge(
                    remainingDays: days,
                    maxPhotos: widget.post.maxPhotos,
                  ),
                );
              },
            ),

            // 삭제 버튼
            if (hasPhoto)
              Positioned(
                left: 14,
                bottom: 14,
                child: _RoundButton(
                  icon: Icons.delete_outline,
                  background: Colors.black.withValues(alpha: 0.5),
                  iconColor: AppColors.textPrimary,
                  size: 44,
                  onTap: _delete,
                ),
              ),

            // 촬영 버튼 — 등록 가능 시간/장수를 넘기면 흐려지지만 **눌리기는 한다**.
            // 아무 반응이 없으면 고장으로 보이므로, 막힌 이유를 알려준다.
            Align(
              alignment: const Alignment(0, 0.92),
              child: _RoundButton(
                icon: Icons.photo_camera_rounded,
                background: widget.post.canAddPhoto
                    ? AppColors.moonlight
                    : AppColors.surfaceHigh,
                iconColor: widget.post.canAddPhoto
                    ? Colors.white
                    : AppColors.textMuted,
                size: 60,
                onTap: _captureOrExplain,
              ),
            ),

            // 페이지 인디케이터(등록된 사진 수 기준)
            if (hasPhoto)
              Positioned(
                right: 16,
                bottom: 24,
                child: Row(
                  children: List.generate(_photos.length, (i) {
                    final active = i == index;
                    return Container(
                      width: active ? 18 : 8,
                      height: 6,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.moonlight
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 앨범 패스 보유 배지. 시안 6의 사진 우상단 오버레이.
class _AlbumPassBadge extends StatelessWidget {
  const _AlbumPassBadge({required this.remainingDays, required this.maxPhotos});

  final int? remainingDays;
  final int maxPhotos;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.moonlight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: AppColors.moonlight, size: 16),
              SizedBox(width: 4),
              Text(
                l10n.homeAlbumPass,
                style: TextStyle(
                  color: AppColors.moonlight,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (remainingDays != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.homeAlbumPassRemaining(remainingDays!),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Text(
              l10n.homeAlbumPassMaxPhotos(maxPhotos),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 부스트 버튼. 사용 중이면 남은 시간을 1초마다 갱신해 보여준다(시안 6-부스트 사용).
class _BoostRow extends ConsumerStatefulWidget {
  const _BoostRow();

  @override
  ConsumerState<_BoostRow> createState() => _BoostRowState();
}

class _BoostRowState extends ConsumerState<_BoostRow> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 남은 시간이 흘러가는 걸 보여주기 위한 것. 활성 부스트가 없으면 굳이 돌지 않는다.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final wallet = ref.read(walletProvider).valueOrNull;
      if (wallet != null && wallet.activeBoosts.isNotEmpty) {
        setState(() {});
      }
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
    final active = wallet.activeBoost(StoreKind.postBoost);
    final stock = wallet.stockOf(StoreKind.postBoost);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: active != null ? const Color(0xFFE8386D) : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        ),
        onPressed: () => Navigator.of(context)
            .push(BoostScreen.route(StoreKind.postBoost)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt,
              color: active != null ? const Color(0xFFE8386D) : AppColors.gold,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              active != null ? l10n.homeBoostActive : l10n.homeBoost,
              style: TextStyle(
                color: active != null
                    ? const Color(0xFFE8386D)
                    : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              active != null ? _clock(active.remaining) : l10n.homeBoostStock(stock),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _clock(Duration remaining) {
    final mm = remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
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

// ── 이름 + 좋아요/댓글 ───────────────────────────────────
class _NameLikeRow extends ConsumerWidget {
  const _NameLikeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 이름·나이·국가는 내 프로필(GET /me) 기준.
    // 좋아요/댓글 수치는 garden 도메인 구현 후 연결 예정.
    final profile = ref.watch(sessionProvider).profile;
    final age = profile?.birthYear == null
        ? null
        : DateTime.now().year - profile!.birthYear!;
    final flag = switch (profile?.country) {
      'KR' => '🇰🇷',
      'JP' => '🇯🇵',
      _ => '',
    };

    return Row(
      children: [
        Flexible(
          child: Text(
            [profile?.nickname ?? '', if (age != null) '$age'].join(' ').trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (flag.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(flag, style: const TextStyle(fontSize: 20)),
        ],
        const Spacer(),
        const _StatPill(
          icon: Icons.favorite,
          iconColor: Color(0xFFE85D6E),
          label: '—',
        ),
        const SizedBox(width: 8),
        const _StatPill(
          icon: Icons.chat_bubble_outline,
          iconColor: AppColors.textSecondary,
          label: '—',
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하루 한 마디 ─────────────────────────────────────────
class _OneLiner extends ConsumerWidget {
  const _OneLiner({required this.post});

  static const int maxLength = 25;

  final MyPost post;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l10n = L10n.of(context);
    final controller = TextEditingController(text: post.oneLiner ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.homeOneLiner,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: maxLength,
          cursorColor: AppColors.moonlight,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.homeOneLinerHint,
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
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    if (text == null || !context.mounted) return;
    final error = await ref.read(myPostProvider.notifier).updateOneLiner(text);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(l10n, error))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final text = post.oneLiner;
    final length = text?.characters.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.homeOneLiner,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$length/$maxLength',
              style: const TextStyle(color: AppColors.gold, fontSize: 14),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _edit(context, ref),
              child: Text(
                text == null || text.isEmpty ? l10n.homeOneLinerWrite : l10n.commonEdit,
                style: const TextStyle(color: AppColors.moonlight),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gapSm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text == null || text.isEmpty ? l10n.homeOneLinerEmpty : text,
                  style: TextStyle(
                    color: text == null || text.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.nightlight_round,
                color: AppColors.moonlight,
                size: 22,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 공유 버튼 ────────────────────────────────────────────
class _ShareButton extends ConsumerWidget {
  const _ShareButton({required this.post});

  final MyPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final enabled = post.gateOpen;

    return SizedBox(
      width: double.infinity,
      height: AppDimens.buttonHeight,
      child: FilledButton.icon(
        onPressed: enabled
            ? () async {
                final error = await ref.read(myPostProvider.notifier).publish();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(error == null ? l10n.homeShared : errorMessage(l10n, error))),
                  );
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3A3E9E),
          disabledBackgroundColor: AppColors.surfaceHigh,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        ),
        icon: Icon(post.published ? Icons.check : Icons.ios_share, size: 20),
        label: Text(
          post.published ? l10n.homeShareAgain : l10n.homeShare,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
