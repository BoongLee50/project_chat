import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../data/models/report_reason.dart';
import '../providers/moderation_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// 신고 팝업. (기획서 화면 16)
///
/// 신고하면 서버가 **친구 관계를 끊고 대화방을 종료**하므로(02 §1.6),
/// 되돌릴 수 없다는 걸 확인 문구로 알린다.
class ReportDialog extends ConsumerStatefulWidget {
  const ReportDialog({
    super.key,
    required this.targetUserId,
    required this.targetNickname,
  });

  final String targetUserId;
  final String targetNickname;

  /// 신고를 마쳤으면 true. 호출한 화면이 뒤로 가기 등을 결정할 수 있게 한다.
  static Future<bool?> show(
    BuildContext context, {
    required String targetUserId,
    required String targetNickname,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (_) => ReportDialog(
          targetUserId: targetUserId,
          targetNickname: targetNickname,
        ),
      );

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  ReportReason? _selected;
  final _detailController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final reason = _selected;
    if (reason == null) return false;
    if (reason.needsDetail && _detailController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _submit() async {
    final reason = _selected;
    if (reason == null) return;

    setState(() => _busy = true);
    final error = await ref.read(moderationActionsProvider).report(
      targetUserId: widget.targetUserId,
      reason: reason.code,
      detail: reason.needsDetail ? _detailController.text.trim() : null,
    );
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
    final l10n = L10n.of(context);
    return Dialog(
      backgroundColor: AppColors.surfaceHigh,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.pagePad,
        vertical: 40,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              children: [
                Text(
                  l10n.reportSelectReason,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  l10n.reportPrivacyNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final reason in ReportReason.values)
                    _ReasonTile(
                      reason: reason,
                      selected: _selected == reason,
                      onTap: () => setState(() => _selected = reason),
                    ),
                  if (_selected?.needsDetail ?? false)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: TextField(
                        controller: _detailController,
                        maxLength: 200,
                        maxLines: 3,
                        onChanged: (_) => setState(() {}),
                        cursorColor: AppColors.moonlight,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.reportDetailHint,
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusMd),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              l10n.reportWarning(widget.targetNickname),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(
                        l10n.commonCancel,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.moonlight,
                        disabledBackgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                      onPressed: (_canSubmit && !_busy) ? _submit : null,
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
                              l10n.reportAction,
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
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

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final ReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.moonlight : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.moonlight : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                reason.label(l10n),
                style: TextStyle(
                  color: selected
                      ? AppColors.moonlight
                      : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
