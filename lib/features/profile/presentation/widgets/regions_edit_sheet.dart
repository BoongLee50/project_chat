import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../data/models/profile_catalog.dart';
import '../providers/profile_edit_provider.dart';

/// 지역 선택. (기획서 화면 24)
///
/// 시안은 국가 하나를 고르고 그 안에서 지역을 고르는 흐름이다.
/// 다만 저장은 **최대 2곳**이고 한국·일본을 섞어 고를 수도 있어야 해서,
/// 국가 탭은 목록을 바꾸는 역할만 하고 선택은 누적된다.
class RegionsEditSheet extends ConsumerStatefulWidget {
  const RegionsEditSheet({super.key, required this.initial, this.homeCountry});

  final List<String> initial;

  /// 내 국가(KR/JP). 처음 보여줄 목록을 정한다.
  final String? homeCountry;

  static Future<bool?> show(
    BuildContext context, {
    required List<String> initial,
    String? homeCountry,
  }) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.night,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) =>
            RegionsEditSheet(initial: initial, homeCountry: homeCountry),
      );

  @override
  ConsumerState<RegionsEditSheet> createState() => _RegionsEditSheetState();
}

class _RegionsEditSheetState extends ConsumerState<RegionsEditSheet> {
  late final Set<String> _selected = {...widget.initial};
  late String _country = _initialCountry();
  bool _busy = false;

  /// 이미 고른 지역이 있으면 그 국가를, 없으면 내 국가를 먼저 보여준다.
  String _initialCountry() {
    for (final code in widget.initial) {
      final country = ProfileCatalog.countryOf(code);
      if (country != null) return country;
    }
    return widget.homeCountry ?? 'KR';
  }

  void _toggle(String code) {
    setState(() {
      if (_selected.contains(code)) {
        _selected.remove(code);
      } else if (_selected.length < ProfileCatalog.maxRegions) {
        _selected.add(code);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('활동 지역은 최대 ${ProfileCatalog.maxRegions}곳까지 선택할 수 있어요.'),
            ),
          );
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final error = await ref
        .read(profileEditActionsProvider)
        .updateRegions(_selected.toList());
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final regions = ProfileCatalog.regionsByCountry[_country] ?? const [];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '지역 선택',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '국가와 지역을 선택해주세요. (최대 ${ProfileCatalog.maxRegions}곳)',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppDimens.gapMd),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePad),
            child: Row(
              children: [
                for (final code in ProfileCatalog.regionsByCountry.keys) ...[
                  Expanded(
                    child: _CountryTab(
                      code: code,
                      selected: _country == code,
                      onTap: () => setState(() => _country = code),
                    ),
                  ),
                  if (code != ProfileCatalog.regionsByCountry.keys.last)
                    const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimens.gapMd),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.pagePad,
                AppDimens.gapMd,
                AppDimens.pagePad,
                AppDimens.gapMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: ProfileCatalog.countryLabel(_country),
                          style: const TextStyle(color: AppColors.moonlight),
                        ),
                        const TextSpan(text: '의 주요 지역'),
                      ],
                    ),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimens.gapMd),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final region in regions)
                        _RegionChip(
                          label: region.label,
                          selected: _selected.contains(region.code),
                          onTap: () => _toggle(region.code),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePad,
              12,
              AppDimens.pagePad,
              0,
            ),
            child: Row(
              children: [
                const Text(
                  '선택한 지역',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selected.isEmpty
                        ? '없음'
                        : _selected.map(ProfileCatalog.regionLabel).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.moonlight,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(
              AppDimens.pagePad,
              12,
              AppDimens.pagePad,
              AppDimens.gapMd,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moonlight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '적용하기',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryTab extends StatelessWidget {
  const _CountryTab({
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.moonlight.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: selected ? AppColors.moonlight : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ProfileCatalog.countryFlag(code),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              ProfileCatalog.countryLabel(code),
              style: TextStyle(
                color: selected ? AppColors.moonlight : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.moonlight.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: selected ? AppColors.moonlight : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.moonlight : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
