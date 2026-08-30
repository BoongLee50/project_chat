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
            // 시안(7장 img18)은 활동 지역 **바로 아래**에 프라임 배너를 둔다.
            // 루나·부스트 카드는 시안에 없지만 이미지가 그 아래에서 잘려 있어
            // 없앤 것으로 볼 수 없다 — 순서만 시안에 맞추고 뒤로 미뤘다.
            if (!profile.premium) ...[
              const _PremiumBanner(),
              const SizedBox(height: AppDimens.gapMd),
            ],
            const _StoreEntry(),
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
        if (profile.premium) ...[
          const _PrimeBadge(),
          const SizedBox(width: 8),
        ],
        // 시안(img18)의 오른쪽 `🟢 접속 중`.
        //
        // 내 프로필이므로 **항상 접속 중**이다 — 이 화면을 보고 있다는 것이 곧 접속이다.
        // 프레즌스에 물을 이유가 없고(내 하트비트를 내가 확인하는 꼴), 물어 봐야
        // 소켓이 잠깐 끊긴 순간에 "오프라인"이 떠서 오히려 이상해진다.
        const _OnlineLabel(),
      ],
    );
  }
}

class _OnlineLabel extends StatelessWidget {
  const _OnlineLabel();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.line,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          l10n.commonOnline,
          style: const TextStyle(
            color: AppColors.line,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
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
                    // 시안(img18)은 연필이 아니라 **`+`** 다 — 관심사·지역은
                    // 고치는 것보다 **더하는** 동작이 앞선다.
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.moonlight,
                      size: 20,
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

/// 프라임 가입 유도 배너(기획 7장 img18).
///
/// 시안은 **혜택 네 칸**을 정확히 이렇게 세운다 —
/// 앨범 패스 / 포스트 부스트 / 대화 신청 무제한 / 자동 번역 무제한.
/// 예전에는 매칭 부스트·무료 업로드·방문자 확인·광고 제거였는데,
/// **매칭 부스트는 Plan_3에서 사라졌고** 나머지 셋은 기획서 어디에도 없다.
///
/// 🚨 **숫자는 문구에 굳히지 않는다.** `30일`·`10매`는 서버 설정(`app.store.*`)이라
/// 카탈로그가 준 값으로 조립한다. 시안의 *"사진 최대 9장"* 은 카탈로그에 없는 값이라
/// 숫자 없이 적었다 — 서버가 알려 주게 되면 그때 넣으면 된다(docs/13 §5).
class _PremiumBanner extends ConsumerWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    // 가장 짧은 플랜을 기준으로 보여 준다 — 배너는 "얼마나 오래"가 아니라
    // "무엇을 받는가"를 말하는 자리다.
    final plans = ref.watch(catalogProvider).valueOrNull?.primePlans ?? const [];
    final plan = plans.isEmpty
        ? null
        : plans.reduce((a, b) => a.durationDays <= b.durationDays ? a : b);

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
                      l10n.primeTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.primeSubtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 시안의 `자세히 보기 >` — 폭을 다 먹는 버튼이 아니라 제목 줄 오른쪽의 작은 칩이다.
              _SeeDetailChip(
                onTap: () => Navigator.of(context).push(PrimeScreen.route()),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapMd),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppDimens.gapMd),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Feature(
                  icon: Icons.photo_camera_outlined,
                  title: plan == null
                      ? l10n.storeKindAlbumPass
                      : l10n.primeAlbumBenefit(plan.durationDays),
                  body: l10n.profilePrimeBenefitAlbumDesc,
                ),
                _Feature(
                  icon: Icons.bolt,
                  title: _boostTitle(l10n, plan),
                  body: l10n.profilePrimeBenefitBoostDesc,
                ),
                _Feature(
                  icon: Icons.chat_bubble_outline,
                  title: l10n.primeUnlimitedChat,
                  body: l10n.profilePrimeBenefitChatDesc,
                ),
                _Feature(
                  icon: Icons.language,
                  title: l10n.profilePrimeBenefitTranslate,
                  body: l10n.profilePrimeBenefitTranslateDesc,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "포스트 부스트 1시간, 10매". 카탈로그가 아직 없으면 매수 없이 이름만.
  static String _boostTitle(L10n l10n, PrimePlan? plan) {
    final count = plan?.boosts[StoreKind.postBoost];
    final name = StoreKind.label(l10n, StoreKind.postBoost);
    return count == null ? name : l10n.primeBoostBenefit(name, count);
  }
}

class _SeeDetailChip extends StatelessWidget {
  const _SeeDetailChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.moonlightDeep,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.profileSeeDetail,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// 혜택 한 칸 — 아이콘 · 굵은 제목 · 설명 두세 줄(시안 img18).
class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.moonlight, size: 26),
            const SizedBox(height: 8),
            // 한 칸이 좁아 한국어가 낱말 가운데서 끊긴다("무제 / 한").
            // 글자를 줄이는 것보다 **칸에 맞춰 줄이는** 편이 안전하다.
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9.5,
                height: 1.35,
              ),
            ),
          ],
        ),
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
