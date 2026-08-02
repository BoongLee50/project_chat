import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import '../widgets/store_widgets.dart';
import 'luna_store_screen.dart';
import '../../../../l10n/app_localizations.dart';

/// 화면 28 — 보유 부스트. 보유 매수를 보고 1매를 써서 1시간 노출을 올린다.
///
/// 포스트 부스트와 스포트라이트 부스트가 같은 구조라 [kind]로 한 화면을 공유한다.
class BoostScreen extends ConsumerStatefulWidget {
  const BoostScreen({super.key, required this.kind});

  final String kind;

  static Route<void> route(String kind) =>
      MaterialPageRoute(builder: (_) => BoostScreen(kind: kind));

  @override
  ConsumerState<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends ConsumerState<BoostScreen> {
  bool _busy = false;

  Color get _accent => widget.kind == StoreKind.postBoost
      ? const Color(0xFFE8386D)
      : AppColors.moonlight;

  Future<void> _use() async {
    final l10n = L10n.of(context);
    setState(() => _busy = true);
    final error = await ref.read(storeActionsProvider).useBoost(widget.kind);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error ?? l10n.boostUsed)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;
    final stock = wallet.stockOf(widget.kind);
    final active = wallet.activeBoost(widget.kind);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: AppColors.night,
        title: Text(
          l10n.boostOwnedTitle(StoreKind.label(l10n, widget.kind)),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePad,
          AppDimens.gapMd,
          AppDimens.pagePad,
          AppDimens.gapLg,
        ),
        children: [
          StoreCard(
            accent: _accent,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
                  child: Icon(
                    widget.kind == StoreKind.postBoost
                        ? Icons.bolt
                        : Icons.star_border_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.boostItemHour(StoreKind.label(l10n, widget.kind)),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                StatusPill(label: l10n.boostStock(stock), color: _accent, filled: false),
              ],
            ),
          ),
          if (active != null) ...[
            const SizedBox(height: AppDimens.gapMd),
            StoreCard(
              accent: _accent,
              child: Row(
                children: [
                  Icon(Icons.timelapse, color: _accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.boostActiveRemaining(_remainingLabel(l10n, active)),
                      style: TextStyle(
                        color: _accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimens.gapLg),
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.moonlight, size: 22),
              SizedBox(width: 8),
              Text(
                l10n.boostEffectTitle,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapSm),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: l10n.boostHourHighlight,
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: l10n.boostHourSuffix,
                ),
              ],
            ),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppDimens.gapMd),
          Row(
            children: [
              Expanded(
                child: _EffectCard(
                  badge: l10n.boostEffectExposure,
                  value: l10n.boostEffectExposureValue,
                  description: l10n.boostEffectExposureDetail,
                  icon: Icons.trending_up,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _EffectCard(
                  badge: l10n.boostEffectVisit,
                  value: l10n.boostEffectVisitValue,
                  description: l10n.boostEffectVisitDetail,
                  icon: Icons.person_add_alt,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _EffectCard(
                  badge: l10n.boostEffectLike,
                  value: l10n.boostEffectLikeValue,
                  description: l10n.boostEffectLikeDetail,
                  icon: Icons.favorite_border,
                ),
              ),
            ],
          ),
          if (stock == 0) ...[
            const SizedBox(height: AppDimens.gapLg),
            StoreCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.boostNone,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.boostBuyHint,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppDimens.gapSm),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacement(LunaStoreScreen.route()),
                    child: Text(l10n.boostGoStore),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: StoreBottomButton(
        label: active != null
            ? l10n.boostInUse
            : (stock == 0 ? l10n.boostNoneShort : l10n.boostUse),
        icon: active == null && stock > 0 ? Icons.bolt : null,
        color: _accent,
        busy: _busy,
        onPressed: (active != null || stock == 0) ? null : _use,
      ),
    );
  }

  String _remainingLabel(L10n l10n, ActiveBoost boost) {
    final remaining = boost.remaining;
    if (remaining.inMinutes < 1) return l10n.boostRemainUnderMinute;
    if (remaining.inHours >= 1) {
      return l10n.boostRemainHourMinute(remaining.inHours, remaining.inMinutes % 60);
    }
    return l10n.boostRemainMinute(remaining.inMinutes);
  }
}

class _EffectCard extends StatelessWidget {
  const _EffectCard({
    required this.badge,
    required this.value,
    required this.description,
    required this.icon,
  });

  final String badge;
  final String value;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            badge,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.moonlight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Icon(icon, color: AppColors.textSecondary, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
