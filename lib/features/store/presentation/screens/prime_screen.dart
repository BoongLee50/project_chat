import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/error_messages.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import '../widgets/store_widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// 화면 26 — 프라임 멤버십.
///
/// 구독 전에는 플랜을 고르고, 구독 중이면 남은 기간과 자동갱신 상태를 보여준다(시안 26-1).
class PrimeScreen extends ConsumerStatefulWidget {
  const PrimeScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const PrimeScreen());

  @override
  ConsumerState<PrimeScreen> createState() => _PrimeScreenState();
}

class _PrimeScreenState extends ConsumerState<PrimeScreen> {
  int _selected = 0;
  bool _busy = false;

  Future<void> _subscribe(PrimePlan plan) async {
    final l10n = L10n.of(context);
    setState(() => _busy = true);
    // 스토어 결제창이 붙기 전까지는 개발용 토큰으로 서버 검증을 태운다(01 §1.8).
    final error = await ref.read(storeActionsProvider).verifyPurchase(
      productId: plan.productId,
      purchaseToken: 'dev-${plan.productId}-${DateTime.now().millisecondsSinceEpoch}',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error == null ? l10n.primeStarted : errorMessage(l10n, error))),
      );
  }

  Future<void> _cancel() async {
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: Text(
          l10n.primeCancelConfirm,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
        ),
        content: Text(
          l10n.primeCancelDetail,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonUnsubscribe, style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await ref.read(storeActionsProvider).cancelSubscription();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error == null ? l10n.primeCancelDone : errorMessage(l10n, error))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final catalog = ref.watch(catalogProvider);
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: StoreAppBar(
        icon: Icons.workspace_premium,
        title: l10n.primeTitle,
        subtitle: l10n.primeSubtitle,
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
          final plans = data.primePlans;
          final plan = plans.isEmpty
              ? null
              : plans[_selected.clamp(0, plans.length - 1)];

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePad,
              AppDimens.gapMd,
              AppDimens.pagePad,
              AppDimens.gapLg,
            ),
            children: [
              const _PrimeBanner(),
              const SizedBox(height: AppDimens.gapLg),
              if (wallet.prime)
                _CurrentSubscription(wallet: wallet, onCancel: _cancel)
              else ...[
                _SectionTitle(l10n.primePlanSection),
                const SizedBox(height: AppDimens.gapSm),
                for (var i = 0; i < plans.length; i++)
                  _PlanTile(
                    plan: plans[i],
                    selected: i == _selected,
                    best: i == plans.length - 1 && plans.length > 1,
                    onTap: () => setState(() => _selected = i),
                  ),
                const SizedBox(height: 6),
                Text(
                  l10n.primeAutoRenewNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
              const SizedBox(height: AppDimens.gapLg),
              _SectionTitle(l10n.primeBenefitsSection),
              const SizedBox(height: AppDimens.gapSm),
              if (plan != null) _Benefits(plan: plan),
              const SizedBox(height: AppDimens.gapMd),
              const _RenewalNote(),
            ],
          );
        },
      ),
      bottomNavigationBar: wallet.prime || catalog.valueOrNull == null
          ? null
          : StoreBottomButton(
              label: l10n.primePay,
              busy: _busy,
              icon: Icons.workspace_premium,
              onPressed: () {
                final plans = catalog.value!.primePlans;
                if (plans.isEmpty) return;
                _subscribe(plans[_selected.clamp(0, plans.length - 1)]);
              },
            ),
    );
  }
}

class _PrimeBanner extends StatelessWidget {
  const _PrimeBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15121F),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.moonlight.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.workspace_premium,
                        color: AppColors.moonlight, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'Prime',
                      style: TextStyle(
                        color: AppColors.moonlight,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.primeHeadlineDetail,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.primeHeadline,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
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

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.best,
    required this.onTap,
  });

  final PrimePlan plan;
  final bool selected;
  final bool best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapSm),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.moonlight.withValues(alpha: 0.16)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(
                  color: selected ? AppColors.moonlight : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? AppColors.moonlight : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.primeMonths(plan.months),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _benefitSummary(l10n, plan),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 현금 가격은 스토어 SDK가 준다(계정 발급 후). 그전까진 자리만 비워 둔다.
                  Text(
                    l10n.primeStorePrice,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (best)
            Positioned(
              left: 14,
              top: -9,
              child: StatusPill(label: l10n.primeBestValue),
            ),
        ],
      ),
    );
  }

  String _benefitSummary(L10n l10n, PrimePlan plan) {
    final parts = <String>[];
    plan.boosts.forEach((kind, count) {
      parts.add(l10n.primeBoostSummary(StoreKind.label(l10n, kind), count));
    });
    return parts.join(' · ');
  }
}

class _CurrentSubscription extends StatelessWidget {
  const _CurrentSubscription({required this.wallet, required this.onCancel});

  final Wallet wallet;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final expires = wallet.subscriptionExpiresAt;
    final remaining = expires?.difference(DateTime.now()).inDays;

    return StoreCard(
      accent: AppColors.moonlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(label: l10n.primeCurrentPlan),
              const Spacer(),
              if (remaining != null)
                Text(
                  l10n.primeRemainingDays(remaining),
                  style: const TextStyle(
                    color: AppColors.moonlight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.gapMd),
          Row(
            children: [
              Text(
                _productLabel(l10n, wallet.subscriptionProduct),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(
                label: wallet.autoRenew ? l10n.primeAutoRenew : l10n.primeAutoRenewOff,
                color: wallet.autoRenew ? AppColors.moonlight : AppColors.gold,
                filled: false,
              ),
            ],
          ),
          if (expires != null) ...[
            const SizedBox(height: 8),
            Text(
              wallet.autoRenew
                  ? l10n.primeNextBilling(_date(expires))
                  : l10n.primeEndDate(_date(expires)),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          if (wallet.autoRenew) ...[
            const SizedBox(height: AppDimens.gapMd),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
                onPressed: onCancel,
                child: Text(
                  l10n.primeCancelRenew,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _productLabel(L10n l10n, String? product) => switch (product) {
    'PRIME_1M' => l10n.primeActiveMonths(1),
    'PRIME_6M' => l10n.primeActiveMonths(6),
    _ => l10n.primeActive,
  };

  String _date(DateTime value) =>
      '${value.year}. ${value.month.toString().padLeft(2, '0')}. '
      '${value.day.toString().padLeft(2, '0')}';
}

class _Benefits extends StatelessWidget {
  const _Benefits({required this.plan});

  final PrimePlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return StoreCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          if (plan.entitlements.contains(StoreKind.albumPass))
            BenefitRow(
              icon: Icons.photo_camera_outlined,
              title: l10n.primeAlbumBenefit(plan.durationDays),
              description: l10n.primeAlbumBenefitDesc,
            ),
          // Plan_3에서 스포트라이트가 폐지돼 부스트는 포스트 부스트 하나뿐이다.
          for (final entry in plan.boosts.entries)
            BenefitRow(
              icon: Icons.trending_up,
              title: l10n.primeBoostBenefit(StoreKind.label(l10n, entry.key), entry.value),
              description: l10n.primePostBoostDesc,
              accent: const Color(0xFFE8386D),
            ),
          if (plan.entitlements.contains(StoreKind.unlimitedChatReq))
            BenefitRow(
              icon: Icons.chat_bubble_outline,
              title: l10n.primeUnlimitedChat,
              description: l10n.primeUnlimitedChatDesc,
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
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _RenewalNote extends StatelessWidget {
  const _RenewalNote();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified_user_outlined,
            color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.primeSubscriptionNotice,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
