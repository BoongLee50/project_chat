import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/error_messages.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import '../widgets/store_widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// 화면 29(포스트 앨범 패스) · 30(자동 번역 패스).
///
/// 두 화면은 혜택 문구만 다르고 구조가 같아 [kind]로 한 화면을 공유한다.
/// 보유 중이면 남은 기간과 이용 정보를, 아니면 "구매 대기" 상태를 보여준다.
class PassScreen extends ConsumerStatefulWidget {
  const PassScreen({super.key, required this.kind});

  final String kind;

  static Route<void> route(String kind) =>
      MaterialPageRoute(builder: (_) => PassScreen(kind: kind));

  @override
  ConsumerState<PassScreen> createState() => _PassScreenState();
}

class _PassScreenState extends ConsumerState<PassScreen> {
  int _selected = 0;
  bool _busy = false;

  bool get _isAlbum => widget.kind == StoreKind.albumPass;

  Color get _accent =>
      _isAlbum ? const Color(0xFF2F7BF6) : const Color(0xFF23A455);

  Future<void> _purchase(LunaProduct product) async {
    final l10n = L10n.of(context);
    setState(() => _busy = true);
    final error = await ref
        .read(storeActionsProvider)
        .purchaseWithLuna(product.id);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error == null ? l10n.passPurchased(StoreKind.label(l10n, widget.kind), product.durationDays) : errorMessage(l10n, error),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final catalog = ref.watch(catalogProvider);
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;

    final active = wallet.has(widget.kind);
    final remaining = wallet.remainingDays(widget.kind);
    final expires = wallet.expiresAt(widget.kind);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: StoreAppBar(
        icon: _isAlbum ? Icons.photo_library_outlined : Icons.language,
        title: StoreKind.label(l10n, widget.kind),
        subtitle: _isAlbum
            ? l10n.passAlbumHeadline
            : l10n.passTranslateHeadline,
        iconColor: _accent,
      ),
      body: catalog.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (error, _) => Center(
          child: Text(l10n.storeLoadFailed,
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        data: (data) {
          final options = data.optionsOf(widget.kind);
          final selected = options.isEmpty
              ? null
              : options[_selected.clamp(0, options.length - 1)];

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePad,
              AppDimens.gapMd,
              AppDimens.pagePad,
              AppDimens.gapLg,
            ),
            children: [
              StoreCard(
                accent: _accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPill(
                          label: active ? l10n.passStatusActive : l10n.passStatusPending,
                          color: _accent,
                          filled: active,
                        ),
                        const Spacer(),
                        if (active && remaining != null)
                          _RemainingBadge(days: remaining, accent: _accent),
                      ],
                    ),
                    const SizedBox(height: AppDimens.gapMd),
                    Text(
                      selected == null
                          ? StoreKind.label(l10n, widget.kind)
                          : l10n.passDaysPass(selected.durationDays),
                      style: TextStyle(
                        color: _accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppDimens.gapMd),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 6),
                    ..._benefits(l10n),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.gapMd),
              _SectionTitle(l10n.passPeriodSection),
              const SizedBox(height: AppDimens.gapSm),
              for (var i = 0; i < options.length; i++)
                PriceOptionTile(
                  label: l10n.passDays(options[i].durationDays),
                  price: options[i].price,
                  selected: i == _selected,
                  accent: _accent,
                  onTap: () => setState(() => _selected = i),
                ),
              const SizedBox(height: AppDimens.gapMd),
              _SectionTitle(l10n.passUsageInfo),
              const SizedBox(height: AppDimens.gapSm),
              StoreCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.star_outline,
                      label: l10n.passAmount,
                      value: selected == null ? '-' : l10n.passPriceLuna(selected.price),
                      valueColor: AppColors.gold,
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    InfoRow(
                      icon: Icons.schedule,
                      label: l10n.passStatus,
                      value: active ? l10n.passStatusActive : l10n.passStatusNone,
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    InfoRow(
                      icon: Icons.event_available,
                      label: l10n.passValidPeriod,
                      value: expires == null ? '-' : l10n.passValidUntil(_date(expires)),
                    ),
                  ],
                ),
              ),
              if (active) ...[
                const SizedBox(height: AppDimens.gapSm),
                Text(
                  l10n.passExtendNotice,
                  style: TextStyle(color: _accent, fontSize: 12),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: catalog.valueOrNull == null
          ? null
          : Builder(
              builder: (context) {
                final options = catalog.value!.optionsOf(widget.kind);
                if (options.isEmpty) return const SizedBox.shrink();
                final selected =
                    options[_selected.clamp(0, options.length - 1)];
                return StoreBottomButton(
                  label: active
                      ? l10n.passExtend(StoreKind.label(l10n, widget.kind))
                      : l10n.passBuy(StoreKind.label(l10n, widget.kind)),
                  price: selected.price,
                  color: _accent,
                  busy: _busy,
                  onPressed: () => _purchase(selected),
                );
              },
            ),
    );
  }

  List<Widget> _benefits(L10n l10n) {
    if (_isAlbum) {
      // 🚨 장수는 **서버 설정**이다(`app.post.max-photos-*`). 문구에 굳혀 두면
      // 설정이 바뀌는 순간 화면이 거짓말을 한다 — 카탈로그가 준 값으로 조립한다.
      final catalog = ref.watch(catalogProvider).valueOrNull;
      final maxPhotos = catalog?.maxPhotosPass ?? 0;
      final freePhotos = catalog?.maxPhotosFree ?? 0;
      return [
        BenefitRow(
          icon: Icons.photo_library_outlined,
          title: l10n.passAlbumBenefit1(maxPhotos),
          description: l10n.passAlbumBenefit1Desc(freePhotos, maxPhotos),
          accent: Color(0xFF2F7BF6),
          checked: false,
        ),
        BenefitRow(
          icon: Icons.photo_camera_back_outlined,
          title: l10n.passAlbumBenefit3,
          description: l10n.passAlbumBenefit3Desc,
          accent: Color(0xFF2F7BF6),
          checked: false,
        ),
        BenefitRow(
          icon: Icons.access_time,
          title: l10n.passAlbumBenefit2,
          description: l10n.passAlbumBenefit2Desc,
          accent: Color(0xFF2F7BF6),
          checked: false,
        ),
      ];
    }
    return [
      BenefitRow(
        icon: Icons.chat_bubble_outline,
        title: l10n.passTranslateBenefit1,
        description: l10n.passTranslateBenefit1Desc,
        accent: Color(0xFF23A455),
        checked: false,
      ),
      BenefitRow(
        icon: Icons.person_outline,
        title: l10n.passTranslateBenefit3,
        description: l10n.passTranslateBenefit3Desc,
        accent: Color(0xFF23A455),
        checked: false,
      ),
      BenefitRow(
        icon: Icons.forum_outlined,
        title: l10n.passTranslateBenefit2,
        description: l10n.passTranslateBenefit2Desc,
        accent: Color(0xFF23A455),
        checked: false,
      ),
    ];
  }

  String _date(DateTime value) =>
      '${value.year}. ${value.month.toString().padLeft(2, '0')}. '
      '${value.day.toString().padLeft(2, '0')}';
}

/// 시안의 원형 "남은 기간" 배지.
class _RemainingBadge extends StatelessWidget {
  const _RemainingBadge({required this.days, required this.accent});

  final int days;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.passRemaining,
            style: TextStyle(color: accent, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.passDays(days),
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
