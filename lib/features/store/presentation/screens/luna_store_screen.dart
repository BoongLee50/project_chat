import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/error_messages.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import '../widgets/store_widgets.dart';
import 'luna_charge_screen.dart';
import 'pass_screen.dart';
import '../../../../l10n/app_localizations.dart';

/// 화면 25 — 루나상점. 보유 루나 + 루나로 사는 상품 4종.
///
/// 가격·구성은 서버 카탈로그에서 온다(`GET /store/products`). 여기에 숫자를 적지 않는다.
class LunaStoreScreen extends ConsumerWidget {
  const LunaStoreScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const LunaStoreScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final catalog = ref.watch(catalogProvider);
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: StoreAppBar(
        icon: Icons.star_rounded,
        title: l10n.lunaStoreTitle,
        subtitle: l10n.lunaStoreSubtitle,
        iconColor: AppColors.gold,
      ),
      body: catalog.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (error, _) => _ErrorView(
          message: l10n.storeLoadFailed,
          onRetry: () => ref.invalidate(catalogProvider),
        ),
        data: (data) => RefreshIndicator(
          color: AppColors.moonlight,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(catalogProvider);
            await ref.read(walletProvider.notifier).refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePad,
              AppDimens.gapMd,
              AppDimens.pagePad,
              AppDimens.gapLg,
            ),
            children: [
              LunaBalanceCard(
                luna: wallet.valueOrNull?.luna ?? 0,
                onCharge: () =>
                    Navigator.of(context).push(LunaChargeScreen.route()),
              ),
              const SizedBox(height: AppDimens.gapMd),
              _ProductSection(
                kind: StoreKind.postBoost,
                icon: Icons.bolt,
                accent: const Color(0xFFE8386D),
                options: data.optionsOf(StoreKind.postBoost),
              ),
              _ProductSection(
                kind: StoreKind.spotlightBoost,
                icon: Icons.star_border_rounded,
                accent: AppColors.moonlight,
                options: data.optionsOf(StoreKind.spotlightBoost),
              ),
              _ProductSection(
                kind: StoreKind.albumPass,
                icon: Icons.photo_camera_outlined,
                accent: const Color(0xFF2F7BF6),
                options: data.optionsOf(StoreKind.albumPass),
                onDetail: () => Navigator.of(context)
                    .push(PassScreen.route(StoreKind.albumPass)),
              ),
              _ProductSection(
                kind: StoreKind.translatePass,
                icon: Icons.translate,
                accent: const Color(0xFF23A455),
                options: data.optionsOf(StoreKind.translatePass),
                onDetail: () => Navigator.of(context)
                    .push(PassScreen.route(StoreKind.translatePass)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상품 한 묶음 — 제목·설명 + 가격 옵션들 + 구매 버튼. 시안 25의 카드 하나.
class _ProductSection extends ConsumerStatefulWidget {
  const _ProductSection({
    required this.kind,
    required this.icon,
    required this.accent,
    required this.options,
    this.onDetail,
  });

  final String kind;
  final IconData icon;
  final Color accent;
  final List<LunaProduct> options;
  final VoidCallback? onDetail;

  @override
  ConsumerState<_ProductSection> createState() => _ProductSectionState();
}

class _ProductSectionState extends ConsumerState<_ProductSection> {
  int _selected = 0;
  bool _busy = false;

  Future<void> _purchase() async {
    final l10n = L10n.of(context);
    if (widget.options.isEmpty) return;
    final product = widget.options[_selected];

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
            error == null
                ? l10n.storePurchased(
                    StoreKind.label(l10n, widget.kind),
                    product.optionLabel(l10n),
                  )
                : errorMessage(l10n, error),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    if (widget.options.isEmpty) return const SizedBox.shrink();

    // 가장 비싼(=많이 담긴) 옵션에 할인 배지. 시안에서 20% 할인이 붙던 자리.
    final maxIndex = widget.options.length - 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapMd),
      child: StoreCard(
        accent: widget.accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    StoreKind.label(l10n, widget.kind),
                    style: TextStyle(
                      color: widget.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (widget.onDetail != null)
                  TextButton(
                    onPressed: widget.onDetail,
                    child: Text(
                      l10n.storeDetail,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              StoreKind.description(l10n, widget.kind),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimens.gapMd),
            for (var i = 0; i < widget.options.length; i++)
              PriceOptionTile(
                label: widget.options[i].optionLabel(l10n),
                price: widget.options[i].price,
                selected: i == _selected,
                accent: widget.accent,
                badge: i == maxIndex && widget.options.length > 1
                    ? _discountBadge(l10n, widget.options)
                    : null,
                onTap: () => setState(() => _selected = i),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
                onPressed: _busy ? null : _purchase,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.storeBuy,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 단가 기준 할인율. 서버가 가격만 주므로 화면에서 계산한다(가격이 바뀌어도 따라간다).
  String? _discountBadge(L10n l10n, List<LunaProduct> options) {
    final base = options.first;
    final top = options.last;
    final baseUnit = base.isBoost ? base.quantity : base.durationDays;
    final topUnit = top.isBoost ? top.quantity : top.durationDays;
    if (baseUnit == 0 || topUnit == 0) return null;

    final basePerUnit = base.price / baseUnit;
    final topPerUnit = top.price / topUnit;
    if (topPerUnit >= basePerUnit) return null;

    final percent = ((1 - topPerUnit / basePerUnit) * 100).round();
    return percent <= 0 ? null : l10n.storeDiscount(percent);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.textMuted, size: 48),
          const SizedBox(height: AppDimens.gapMd),
          Text(
            message,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
          const SizedBox(height: AppDimens.gapMd),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
