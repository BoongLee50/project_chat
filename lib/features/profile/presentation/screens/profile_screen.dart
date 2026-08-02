import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../store/data/models/store_models.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../../../store/presentation/screens/boost_screen.dart';
import '../../../store/presentation/screens/luna_store_screen.dart';
import '../../../store/presentation/screens/prime_screen.dart';
import '../../data/models/me_profile.dart';
import '../../data/models/profile_catalog.dart';
import '../widgets/interests_edit_sheet.dart';
import '../widgets/intro_edit_dialog.dart';
import '../widgets/regions_edit_sheet.dart';

/// 프로필 — 메인 셸의 '프로필' 탭 본문. (기획서 7장)
///
/// `GET /me` 응답(세션이 보유)을 그대로 표시한다. 사진/관심사/소개/지역 **편집**은
/// 서버 엔드포인트는 있으나 아직 화면 미구현(다음 단계).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              title: '관심사',
              onEdit: () =>
                  InterestsEditSheet.show(context, profile.interests),
              child: profile.interests.isEmpty
                  ? const _EmptyHint('관심사를 등록하면 더 잘 맞는 사람을 만날 수 있어요.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final code in profile.interests)
                          _Chip(label: ProfileCatalog.interestLabel(code)),
                      ],
                    ),
            ),
            const SizedBox(height: AppDimens.gapMd),
            _SectionCard(
              icon: Icons.format_quote,
              title: '소개 한마디',
              onEdit: () =>
                  IntroEditDialog.show(context, initial: profile.intro),
              child: (profile.intro == null || profile.intro!.isEmpty)
                  ? const _EmptyHint('나를 소개하는 한마디를 남겨보세요. (최대 50자)')
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
              title: '활동 지역',
              onEdit: () => RegionsEditSheet.show(
                context,
                initial: profile.regions,
                homeCountry: profile.country,
              ),
              child: profile.regions.isEmpty
                  ? const _EmptyHint('활동 지역은 최대 2곳까지 선택할 수 있어요.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final code in profile.regions)
                          _Chip(label: ProfileCatalog.regionLabel(code)),
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
    return Row(
      children: [
        const Text(
          '프로필',
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
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'signOut',
              child: Text(
                '로그아웃',
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
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: AspectRatio(
        aspectRatio: 1.05,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl != null)
              Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
              )
            else
              const _PhotoPlaceholder(),
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.white,
                  size: 22,
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
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.person_outline, color: AppColors.textMuted, size: 56),
          SizedBox(height: 12),
          Text(
            '프로필 사진을 등록해 주세요',
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
              const Text(
                '보유 루나',
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
                child: const Text('루나상점'),
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
                label: '포스트 부스트',
                badge: wallet.stockOf(StoreKind.postBoost),
                onTap: () => Navigator.of(context)
                    .push(BoostScreen.route(StoreKind.postBoost)),
              ),
            ),
            const SizedBox(width: AppDimens.gapSm),
            Expanded(
              child: _StoreShortcut(
                icon: Icons.star_border_rounded,
                label: '스포트라이트',
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
              '$badge매',
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '프라임으로 더 특별하게 ✨',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '포스트 8장·부스트·무제한 대화·자동 번역',
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
              child: const Text(
                '자세히 보기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.gapMd),
          Row(
            children: const [
              _Feature(icon: Icons.bolt, label: '매칭 부스트'),
              _Feature(icon: Icons.cloud_upload_outlined, label: '무료 업로드'),
              _Feature(icon: Icons.visibility_outlined, label: '방문자 확인'),
              _Feature(icon: Icons.block, label: '광고 제거'),
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
