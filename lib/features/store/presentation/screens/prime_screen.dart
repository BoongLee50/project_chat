import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import '../widgets/store_widgets.dart';

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
        SnackBar(content: Text(error ?? 'PRIME 멤버십이 시작됐어요!')),
      );
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text(
          '자동 갱신을 해지할까요?',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
        ),
        content: const Text(
          '남은 기간 동안은 혜택이 그대로 유지되고, 만료일에 갱신되지 않아요.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('해지', style: TextStyle(color: AppColors.gold)),
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
        SnackBar(content: Text(error ?? '자동 갱신을 해지했어요.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: const StoreAppBar(
        icon: Icons.workspace_premium,
        title: 'PRIME 멤버십',
        subtitle: 'PRIME으로 더 특별한 경험을 즐겨보세요.',
      ),
      body: catalog.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (error, _) => const Center(
          child: Text('상품을 불러오지 못했어요.',
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
                const _SectionTitle('요금제 선택하기'),
                const SizedBox(height: AppDimens.gapSm),
                for (var i = 0; i < plans.length; i++)
                  _PlanTile(
                    plan: plans[i],
                    selected: i == _selected,
                    best: i == plans.length - 1 && plans.length > 1,
                    onTap: () => setState(() => _selected = i),
                  ),
                const SizedBox(height: 6),
                const Text(
                  '* PRIME은 선택하신 기간 동안 혜택이 자동 갱신됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
              const SizedBox(height: AppDimens.gapLg),
              const _SectionTitle('프라임 혜택'),
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
              label: '결제하기',
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
                const Text(
                  '모든 기능을 제한 없이!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '달빛톡을 완벽하게 즐기는 방법',
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
                          '${plan.months}개월',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _benefitSummary(plan),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 현금 가격은 스토어 SDK가 준다(계정 발급 후). 그전까진 자리만 비워 둔다.
                  const Text(
                    '스토어 가격',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (best)
            const Positioned(
              left: 14,
              top: -9,
              child: StatusPill(label: '가성비 끝판왕'),
            ),
        ],
      ),
    );
  }

  String _benefitSummary(PrimePlan plan) {
    final parts = <String>[];
    plan.boosts.forEach((kind, count) {
      parts.add('${StoreKind.label(kind)} $count매');
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
    final expires = wallet.subscriptionExpiresAt;
    final remaining = expires?.difference(DateTime.now()).inDays;

    return StoreCard(
      accent: AppColors.moonlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusPill(label: '현재 적용 중'),
              const Spacer(),
              if (remaining != null)
                Text(
                  '남은 기간 $remaining일',
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
                _productLabel(wallet.subscriptionProduct),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(
                label: wallet.autoRenew ? '자동 갱신' : '갱신 안 함',
                color: wallet.autoRenew ? AppColors.moonlight : AppColors.gold,
                filled: false,
              ),
            ],
          ),
          if (expires != null) ...[
            const SizedBox(height: 8),
            Text(
              wallet.autoRenew
                  ? '다음 결제 예정일  ${_date(expires)}'
                  : '이용 종료일  ${_date(expires)}',
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
                child: const Text(
                  '자동 갱신 해지',
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

  String _productLabel(String? product) => switch (product) {
    'PRIME_1M' => '1개월 이용 중',
    'PRIME_6M' => '6개월 이용 중',
    _ => 'PRIME 이용 중',
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
    return StoreCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          if (plan.entitlements.contains(StoreKind.albumPass))
            BenefitRow(
              icon: Icons.photo_camera_outlined,
              title: '포스트 사진 앨범 패스 ${plan.durationDays}일',
              description: '하루에 여러 장의 사진을 자유롭게 업로드!',
            ),
          for (final entry in plan.boosts.entries)
            BenefitRow(
              icon: entry.key == StoreKind.postBoost
                  ? Icons.trending_up
                  : Icons.star_border_rounded,
              title: '${StoreKind.label(entry.key)} 1시간, ${entry.value}매',
              description: entry.key == StoreKind.postBoost
                  ? '내 포스트를 더 많은 사람에게 노출! (일일제한 없음)'
                  : '오늘의 주인공이 되어 더 많은 관심을! (일일제한 없음)',
              accent: entry.key == StoreKind.postBoost
                  ? const Color(0xFFE8386D)
                  : AppColors.moonlight,
            ),
          if (plan.entitlements.contains(StoreKind.unlimitedChatReq))
            const BenefitRow(
              icon: Icons.chat_bubble_outline,
              title: '대화 신청 무제한',
              description: '하루 무료 횟수에 관계없이 대화를 신청할 수 있어요.',
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.verified_user_outlined,
            color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            '구독 서비스는 동일한 기간, 동일한 가격으로 자동 갱신되며,\n'
            '언제든 구독을 해지할 수 있습니다.',
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
