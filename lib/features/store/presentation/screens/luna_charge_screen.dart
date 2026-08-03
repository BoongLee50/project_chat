import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/error_messages.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import '../widgets/store_widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// 화면 27 — 루나 충전샵. 인앱결제로 루나를 산다.
///
/// **현금 표시가는 아직 없다.** 스토어 콘솔에 상품을 등록해야 SDK가 현지 가격을 주고,
/// 그건 개발자 계정이 생긴 뒤의 일이다(01 §1.8). 지금은 구성(루나 수·보너스)만 보여주고
/// 결제는 개발용 검증기로 흘린다.
class LunaChargeScreen extends ConsumerStatefulWidget {
  const LunaChargeScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const LunaChargeScreen());

  @override
  ConsumerState<LunaChargeScreen> createState() => _LunaChargeScreenState();
}

class _LunaChargeScreenState extends ConsumerState<LunaChargeScreen> {
  String? _busyProductId;

  Future<void> _charge(LunaPack pack) async {
    final l10n = L10n.of(context);
    setState(() => _busyProductId = pack.productId);

    // 스토어 결제창(in_app_purchase)이 붙기 전까지는 개발용 토큰으로 서버에 검증을 요청한다.
    // 서버의 MockReceiptVerifier가 'dev-'로 시작하는 토큰만 통과시킨다.
    final error = await ref.read(storeActionsProvider).verifyPurchase(
      productId: pack.productId,
      purchaseToken: 'dev-${pack.productId}-${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    setState(() => _busyProductId = null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error == null ? l10n.chargeDone(pack.total) : errorMessage(l10n, error))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final catalog = ref.watch(catalogProvider);
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: StoreAppBar(
        icon: Icons.star_rounded,
        title: l10n.chargeTitle,
        subtitle: l10n.chargeSubtitle,
        iconColor: AppColors.gold,
      ),
      body: catalog.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (error, _) => Center(
          child: Text(
            l10n.storeLoadFailed,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.pagePad,
            AppDimens.gapMd,
            AppDimens.pagePad,
            AppDimens.gapLg,
          ),
          children: [
            LunaBalanceCard(luna: wallet.valueOrNull?.luna ?? 0),
            const SizedBox(height: AppDimens.gapMd),
            for (final pack in data.lunaPacks)
              _PackCard(
                pack: pack,
                busy: _busyProductId == pack.productId,
                onTap: _busyProductId == null ? () => _charge(pack) : null,
              ),
            const SizedBox(height: AppDimens.gapMd),
            const _SafePaymentNote(),
          ],
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack, required this.onTap, required this.busy});

  final LunaPack pack;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapSm),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          StoreCard(
            accent: pack.hasBonus ? AppColors.gold : null,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            l10n.chargeLunaPrefix,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${pack.total}',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            l10n.chargeLunaSuffix,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (pack.hasBonus)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.chargeBaseBonus(pack.luna, pack.bonus),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.moonlight,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                    onPressed: onTap,
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.chargeBuy,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (pack.hasBonus)
            Positioned(
              left: 12,
              top: -8,
              child: StatusPill(
                label: l10n.chargeBonusBadge(pack.bonus),
                color: AppColors.gold,
              ),
            ),
        ],
      ),
    );
  }
}

class _SafePaymentNote extends StatelessWidget {
  const _SafePaymentNote();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return StoreCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              color: AppColors.moonlight, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chargeSecure,
                  style: TextStyle(
                    color: AppColors.moonlight,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  l10n.chargeNotice,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
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
