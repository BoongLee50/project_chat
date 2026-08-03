import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/error_messages.dart';
import '../../data/models/profile_catalog.dart';
import '../providers/profile_edit_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// 관심사 등록. (기획서 화면 22)
///
/// 항목이 40개 가까이 되고 그룹이 접히므로 다이얼로그보다 **전체 화면 시트**가 맞다.
class InterestsEditSheet extends ConsumerStatefulWidget {
  const InterestsEditSheet({super.key, required this.initial});

  final List<String> initial;

  static Future<bool?> show(BuildContext context, List<String> initial) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.night,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => InterestsEditSheet(initial: initial),
      );

  @override
  ConsumerState<InterestsEditSheet> createState() => _InterestsEditSheetState();
}

class _InterestsEditSheetState extends ConsumerState<InterestsEditSheet> {
  late final Set<String> _selected = {...widget.initial};
  late final Set<String> _expanded = {
    // 처음엔 앞의 두 그룹만 펼쳐 둔다(시안과 동일).
    ProfileCatalog.interestGroups[0].code,
    ProfileCatalog.interestGroups[1].code,
  };
  bool _busy = false;

  void _toggle(String code) {
    setState(() {
      if (_selected.contains(code)) {
        _selected.remove(code);
      } else if (_selected.length < ProfileCatalog.maxInterests) {
        _selected.add(code);
      } else {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.interestsEditLimit(ProfileCatalog.maxInterests)),
            ),
          );
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final error = await ref
        .read(profileEditActionsProvider)
        .updateInterests(_selected.toList());
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(L10n.of(context), error))));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
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
          Text(
            l10n.interestsEditTitle,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.interestsEditSubtitle,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppDimens.gapMd),
          _SelectedBar(
            selected: _selected.toList(),
            onRemove: (code) => setState(() => _selected.remove(code)),
            onClear: () => setState(_selected.clear),
          ),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.pagePad,
                AppDimens.gapMd,
                AppDimens.pagePad,
                AppDimens.gapMd,
              ),
              children: [
                for (final group in ProfileCatalog.interestGroups)
                  _Group(
                    group: group,
                    expanded: _expanded.contains(group.code),
                    selected: _selected,
                    onToggleGroup: () => setState(() {
                      if (!_expanded.remove(group.code)) {
                        _expanded.add(group.code);
                      }
                    }),
                    onToggleItem: _toggle,
                  ),
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(
              AppDimens.pagePad,
              0,
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
                    : Text(
                        l10n.interestsEditSave(_selected.length, ProfileCatalog.maxInterests),
                        style: const TextStyle(
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

/// 선택된 관심사 칩 + 전체 초기화.
class _SelectedBar extends StatelessWidget {
  const _SelectedBar({
    required this.selected,
    required this.onRemove,
    required this.onClear,
  });

  final List<String> selected;
  final void Function(String code) onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePad,
        0,
        AppDimens.pagePad,
        AppDimens.gapMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.interestsEditSelected(selected.length, ProfileCatalog.maxInterests),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (selected.isNotEmpty)
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l10n.interestsEditReset),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (selected.isEmpty)
            Text(
              l10n.interestsEditEmpty,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in selected)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
                    decoration: BoxDecoration(
                      color: AppColors.moonlight.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ProfileCatalog.interestIcon(code),
                          color: AppColors.moonlight,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ProfileCatalog.interestLabel(l10n, code),
                          style: const TextStyle(
                            color: AppColors.moonlight,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => onRemove(code),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.moonlight,
                            size: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.group,
    required this.expanded,
    required this.selected,
    required this.onToggleGroup,
    required this.onToggleItem,
  });

  final InterestGroup group;
  final bool expanded;
  final Set<String> selected;
  final VoidCallback onToggleGroup;
  final void Function(String code) onToggleItem;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pickedInGroup =
        group.items.where((item) => selected.contains(item.code)).length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.gapMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            onTap: onToggleGroup,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(group.icon, color: AppColors.moonlight, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    ProfileCatalog.groupTitle(l10n, group.code),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (pickedInGroup > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.moonlight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pickedInGroup',
                        style: const TextStyle(
                          color: AppColors.moonlight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in group.items)
                    _InterestChip(
                      item: item,
                      selected: selected.contains(item.code),
                      onTap: () => onToggleItem(item.code),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final InterestItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.moonlight.withValues(alpha: 0.18)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: selected ? AppColors.moonlight : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 17,
              color: selected ? AppColors.moonlight : AppColors.textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              ProfileCatalog.interestLabel(l10n, item.code),
              style: TextStyle(
                color: selected ? AppColors.moonlight : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle,
                  size: 15, color: AppColors.moonlight),
            ],
          ],
        ),
      ),
    );
  }
}
