import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../l10n/app_localizations.dart';

/// 이모지 고르기(기획 §2-5 · 화면 5).
///
/// 기획서는 *"이모지는 스마트폰에 내장되어 있는 기본 이미지 패널 호출"* 이라고 적었다.
/// 그런데 **Flutter에서 시스템 키보드의 이모지 탭만 따로 열 수는 없다** —
/// 키보드를 띄우는 것까지가 전부고, 이모지 탭으로 넘어가는 건 사용자 몫이다.
/// 그래서 버튼을 눌렀을 때 아무 일도 안 일어난 것처럼 보이지 않도록 이 시트를 둔다.
///
/// 자주 쓰는 것만 담았다. 전체 이모지를 나열하면 이 시트가 곧 키보드가 되는데,
/// 그건 기획이 원한 "기본 패널"과 다르고 유지할 값도 아니다 —
/// 사용자는 키보드에서 언제든 더 고를 수 있다.
///
/// 📌 이모지는 **글자**다. 붙이면 그대로 텍스트 메시지로 나간다(새 메시지 유형이 아니다).
Future<String?> showEmojiSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
    ),
    builder: (context) => const _EmojiSheet(),
  );
}

class _EmojiSheet extends StatelessWidget {
  const _EmojiSheet();

  /// 밤에 나누는 대화에서 자주 쓸 만한 것들. 순서에 뜻은 없다.
  static const _emojis = <String>[
    '😊', '😄', '🥰', '😍', '😆', '😅', '🙂', '😉',
    '😌', '😴', '🤔', '😮', '😢', '🥺', '😭', '😳',
    '👍', '👏', '🙏', '🤝', '✌️', '🫶', '💪', '🙌',
    '❤️', '💜', '💛', '✨', '🌙', '⭐', '🌸', '🍀',
    '🎉', '🎂', '☕', '🍜', '🍰', '🍺', '🎵', '📷',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gapMd,
          AppDimens.gapMd,
          AppDimens.gapMd,
          AppDimens.gapMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.chatEmojiRecent,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimens.gapSm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, i) => InkWell(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                onTap: () => Navigator.pop(context, _emojis[i]),
                child: Center(
                  child: Text(
                    _emojis[i],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
