import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import '../widgets/store_widgets.dart';
import 'luna_store_screen.dart';

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
    setState(() => _busy = true);
    final error = await ref.read(storeActionsProvider).useBoost(widget.kind);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error ?? '부스트를 사용했어요. 1시간 동안 우선 노출됩니다!')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;
    final stock = wallet.stockOf(widget.kind);
    final active = wallet.activeBoost(widget.kind);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: AppColors.night,
        title: Text(
          '보유 ${StoreKind.label(widget.kind)}',
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
                    '${StoreKind.label(widget.kind)} (1시간)',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                StatusPill(label: '보유 $stock매', color: _accent, filled: false),
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
                      '사용 중 — ${_remainingLabel(active)} 남음',
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
            children: const [
              Icon(Icons.auto_awesome, color: AppColors.moonlight, size: 22),
              SizedBox(width: 8),
              Text(
                '예상 효과',
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
                  text: '1시간',
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
                ),
                const TextSpan(
                  text: ' 동안 추천 우선순위가 올라가\n더 많은 사용자에게 노출돼요!',
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
            children: const [
              Expanded(
                child: _EffectCard(
                  badge: '최대 노출 증가',
                  value: '약 3배',
                  description: '더 많은 사용자에게 노출돼요',
                  icon: Icons.trending_up,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _EffectCard(
                  badge: '프로필 방문 증가',
                  value: '약 2.5배',
                  description: '프로필 방문 및 유입이 늘어나요',
                  icon: Icons.person_add_alt,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _EffectCard(
                  badge: '좋아요 증가',
                  value: '약 2배',
                  description: '좋아요와 관심을 더 많이 받아요',
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
                  const Text(
                    '보유한 부스트가 없어요.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '루나상점에서 부스트를 구매할 수 있어요.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppDimens.gapSm),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacement(LunaStoreScreen.route()),
                    child: const Text('루나상점 가기'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: StoreBottomButton(
        label: active != null
            ? '사용 중이에요'
            : (stock == 0 ? '보유한 부스트가 없어요' : '부스트 사용하기 (1매)'),
        icon: active == null && stock > 0 ? Icons.bolt : null,
        color: _accent,
        busy: _busy,
        onPressed: (active != null || stock == 0) ? null : _use,
      ),
    );
  }

  String _remainingLabel(ActiveBoost boost) {
    final remaining = boost.remaining;
    if (remaining.inMinutes < 1) return '1분 미만';
    if (remaining.inHours >= 1) {
      return '${remaining.inHours}시간 ${remaining.inMinutes % 60}분';
    }
    return '${remaining.inMinutes}분';
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
