import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/photo_source_sheet.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../store/data/models/store_models.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../../../store/presentation/screens/boost_screen.dart';
import '../../../store/presentation/screens/luna_store_screen.dart';
import '../../../store/presentation/screens/prime_screen.dart';
import '../../data/models/me_profile.dart';
import '../../data/models/profile_catalog.dart';
import '../providers/profile_edit_provider.dart';
import '../widgets/interests_edit_sheet.dart';
import '../widgets/intro_edit_dialog.dart';
import '../widgets/regions_edit_sheet.dart';
import '../../../../l10n/app_localizations.dart';

/// 프로필 — 메인 셸의 l10n.profileTitle 탭 본문. (기획서 7장)
///
/// `GET /me` 응답(세션이 보유)을 그대로 표시한다. 사진·관심사·소개·지역 편집은
/// 모두 여기서 바로 하고, 저장 후 세션을 다시 읽어 화면이 즉시 따라온다.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final profile = ref.watch(sessionProvider).profile;

    if (profile == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.moonlight),
      );
    }

    return RefreshIndicator(
      color: AppColors.moonlight,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(sessionProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePad,
          AppDimens.gapMd,
          AppDimens.pagePad,
          AppDimens.gapLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const SizedBox(height: AppDimens.gapMd),
            _PhotoCard(photoUrl: profile.photoUrl),
            const SizedBox(height: AppDimens.gapMd),
            _NameRow(profile: profile),
            const SizedBox(height: AppDimens.gapLg),
            _SectionCard(
              icon: Icons.favorite_border,
              title: l10n.profileInterests,
              onEdit: () =>
                  InterestsEditSheet.show(context, profile.interests),
              child: profile.interests.isEmpty
                  ? _EmptyHint(l10n.profileInterestsEmpty)
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final code in profile.interests)
                          _Chip(label: ProfileCatalog.interestLabel(l10n, code)),
                      ],
                    ),
            ),
            const SizedBox(height: AppDimens.gapMd),
            _SectionCard(
              icon: Icons.format_quote,
              title: l10n.profileIntro,
              onEdit: () =>
                  IntroEditDialog.show(context, initial: profile.intro),
              child: (profile.intro == null || profile.intro!.isEmpty)
                  ? _EmptyHint(l10n.profileIntroEmpty)
                  : Text(
                      profile.intro!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
            ),
            const SizedBox(height: AppDimens.gapMd),
            _SectionCard(
              icon: Icons.location_on_outlined,
              title: l10n.profileRegions,
              onEdit: () => RegionsEditSheet.show(
                context,
                initial: profile.regions,
                homeCountry: profile.country,
              ),
              child: profile.regions.isEmpty
                  ? _EmptyHint(l10n.profileRegionsEmpty)
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final code in profile.regions)
                          _Chip(label: ProfileCatalog.regionLabel(l10n, code)),
                      ],
                    ),
            ),
            const SizedBox(height: AppDimens.gapLg),
            const _StoreEntry(),
            const SizedBox(height: AppDimens.gapMd),
            if (!profile.premium) const _PremiumBanner(),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Text(
          l10n.profileTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        const _Dot(),
        const Spacer(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
          color: AppColors.surfaceHigh,
          onSelected: (value) {
            if (value == 'signOut') {
              ref.read(sessionProvider.notifier).signOut();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'signOut',
              child: Text(
                l10n.profileLogout,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 프로필 사진. 아직 등록 전이면 등록 안내 플레이스홀더를 보여준다.
///
/// 사진 버튼을 누르면 선택 시트(앨범·촬영·제거)가 뜬다. 프로필 사진은 포스트와 달리
/// **운영시간 게이트도 등록 창 제한도 없고 앨범도 패스 없이 쓸 수 있다**
/// (서버 `ProfileService`에 게이트 검사가 없다) — 친구·상점과 같이 24시간 열린 영역이다.
class _PhotoCard extends ConsumerStatefulWidget {
  const _PhotoCard({this.photoUrl});

  final String? photoUrl;

  @override
  ConsumerState<_PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends ConsumerState<_PhotoCard> {
  bool _busy = false;

  /// 사진 버튼 → 선택 시트 → 고른 대로 실행.
  ///
  /// 제거는 **사진이 있을 때만** 열어 준다. 없는데 눌리면 할 일이 없어서다.
  Future<void> _pick() async {
    if (_busy) return;
    final hasPhoto = widget.photoUrl != null;
    final l10n = L10n.of(context);

    final choice = await PhotoSourceSheet.show(
      context,
      title: l10n.photoSheetProfileTitle,
      subtitle: l10n.photoSheetProfileSubtitle,
      showRemove: true,
      removeEnabled: hasPhoto,
    );
    if (choice == null || !mounted) return;

    if (choice == PhotoSource.remove) return _remove();

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: choice == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await _run(() => ref.read(profileEditActionsProvider).updatePhoto(bytes));
  }

  Future<void> _remove() =>
      _run(() => ref.read(profileEditActionsProvider).deletePhoto());

  /// 통신 동안 버튼을 스피너로 바꾸고, 실패하면 이유를 알려준다.
  Future<void> _run(Future<ApiException?> Function() action) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(errorMessage(L10n.of(context), error))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: AspectRatio(
        aspectRatio: 1.05,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.photoUrl != null)
              // 맨 `Image.network`를 쓰면 안 된다 — 서버가 주는 `/files?key=...`는
              // **상대경로**이고 JWT도 요구하는데, Image.network는 dio 인터셉터를
              // 타지 않아 항상 실패하고 조용히 플레이스홀더로 되돌아간다.
              AuthedImage(
                url: widget.photoUrl!,
                fallback: const _PhotoPlaceholder(),
              )
            else
              const _PhotoPlaceholder(),
            Positioned(
              right: 14,
              bottom: 14,
              child: GestureDetector(
                onTap: _pick,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70),
                  ),
                  child: _busy
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.photo_camera_outlined,
                          color: Colors.white,
                          size: 22,
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

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, color: AppColors.textMuted, size: 56),
          SizedBox(height: 12),
          Text(
            l10n.profilePhotoPrompt,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.profile});

  final MeProfile profile;

  @override
  Widget build(BuildContext context) {
    // 서버는 출생년도만 주므로 연 단위로 계산한다.
    final age = profile.birthYear == null
        ? null
        : DateTime.now().year - profile.birthYear!;
    final flag = switch (profile.country) {
      'KR' => '🇰🇷',
      'JP' => '🇯🇵',
      _ => '',
    };

    return Row(
      children: [
        Flexible(
          child: Text(
            [profile.nickname ?? '', if (age != null) '$age'].join(' ').trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (flag.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(flag, style: const TextStyle(fontSize: 20)),
        ],
        const Spacer(),
        if (profile.premium) const _PrimeBadge(),
      ],
    );
  }
}

class _PrimeBadge extends StatelessWidget {
  const _PrimeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.workspace_premium, color: AppColors.gold, size: 16),
          SizedBox(width: 4),
          Text(
            'PRIME',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.onEdit,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// 편집 버튼(+). 없으면 버튼을 숨긴다.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.moonlight, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (onEdit != null)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEdit,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.moonlight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: AppColors.moonlight,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.gapMd),
          child,
        ],
      ),
    );
  }
}

/// 관심사·지역 태그. 서버는 코드를 주므로 카탈로그로 표시명을 찾아 그린다
/// (카탈로그에 없는 코드는 코드 그대로 — 구버전 데이터 대비).
class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.moonlight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 루나 잔액 + 상점/부스트 진입. 프로필에서 BM 화면들로 들어가는 문이다.
class _StoreEntry extends ConsumerWidget {
  const _StoreEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.profileLunaBalance,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${wallet.luna}',
                style: const TextStyle(
                  color: AppColors.moonlight,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moonlight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () =>
                    Navigator.of(context).push(LunaStoreScreen.route()),
                child: Text(l10n.profileLunaStore),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.gapSm),
        Row(
          children: [
            Expanded(
              child: _StoreShortcut(
                icon: Icons.bolt,
                label: l10n.profileBoostPost,
                badge: wallet.stockOf(StoreKind.postBoost),
                onTap: () => Navigator.of(context)
                    .push(BoostScreen.route(StoreKind.postBoost)),
              ),
            ),
            const SizedBox(width: AppDimens.gapSm),
            Expanded(
              child: _StoreShortcut(
                icon: Icons.star_border_rounded,
                label: l10n.profileSpotlight,
                badge: wallet.stockOf(StoreKind.spotlightBoost),
                onTap: () => Navigator.of(context)
                    .push(BoostScreen.route(StoreKind.spotlightBoost)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StoreShortcut extends StatelessWidget {
  const _StoreShortcut({
    required this.icon,
    required this.label,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.moonlight, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              l10n.profileBoostCount(badge),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        gradient: const LinearGradient(
          colors: [Color(0xFF241E4E), Color(0xFF1A1730)],
        ),
        border: Border.all(color: AppColors.moonlight.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.moonlightDeep,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profilePrimeTitle,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      l10n.profilePrimeBenefits,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapMd),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () =>
                  Navigator.of(context).push(PrimeScreen.route()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.moonlightDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
              child: Text(
                l10n.profileSeeDetail,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.gapMd),
          Row(
            children: [
              _Feature(icon: Icons.bolt, label: l10n.profileBoostMatch),
              _Feature(icon: Icons.cloud_upload_outlined, label: l10n.profileFreeUpload),
              _Feature(icon: Icons.visibility_outlined, label: l10n.profileVisitors),
              _Feature(icon: Icons.block, label: l10n.profileNoAds),
            ],
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.moonlight, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
