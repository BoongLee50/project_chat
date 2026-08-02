import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../providers/moderation_provider.dart';

/// 차단 팝업. (기획서 화면 17)
class BlockDialog extends ConsumerStatefulWidget {
  const BlockDialog({
    super.key,
    required this.targetUserId,
    required this.targetNickname,
  });

  final String targetUserId;
  final String targetNickname;

  /// 차단을 마쳤으면 true.
  static Future<bool?> show(
    BuildContext context, {
    required String targetUserId,
    required String targetNickname,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (_) => BlockDialog(
          targetUserId: targetUserId,
          targetNickname: targetNickname,
        ),
      );

  @override
  ConsumerState<BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends ConsumerState<BlockDialog> {
  bool _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    final error =
        await ref.read(moderationActionsProvider).block(widget.targetUserId);
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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: widget.targetNickname,
                        style: const TextStyle(color: AppColors.moonlight),
                      ),
                      const TextSpan(text: '님을 차단하시겠습니까?'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '차단하면 상대방과의 채팅이 중단되고,\n'
                  '상대방은 더 이상 나에게 메시지를 보낼 수 없습니다.',
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
          const SizedBox(height: 18),
          const Divider(color: AppColors.border, height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                _BlockEffect(
                  icon: Icons.forum_outlined,
                  title: '채팅 차단',
                  description: '상대방과의 채팅이 중단되며,\n더 이상 메시지를 주고받을 수 없습니다.',
                ),
                SizedBox(height: 18),
                _BlockEffect(
                  icon: Icons.person_off_outlined,
                  title: '프로필 비공개',
                  description: '상대방이 내 프로필과 소식을\n볼 수 없게 됩니다.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
                      child: const Text(
                        '취소',
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
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '차단하기',
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

class _BlockEffect extends StatelessWidget {
  const _BlockEffect({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.moonlight.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.moonlight, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
