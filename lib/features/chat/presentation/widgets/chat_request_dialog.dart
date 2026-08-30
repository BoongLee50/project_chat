import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// 대화 신청 한마디를 받는 팝업(기획 4-3).
///
/// 달빛가든 카드와 [포스트 정보] 화면이 같은 팝업을 띄운다 — 두 곳에 따로 두었더니
/// 글자 수 제한 같은 걸 한쪽만 고치게 된다.
///
/// 보낸 것까지 하지 않고 **입력받은 한마디만** 돌려준다. 하루 무료 2회 후 루나 5 차감은
/// 서버가 판정하므로, 부르는 쪽이 결과 문구를 자기 화면에 맞게 보여 주면 된다.
Future<String?> showChatRequestDialog(
  BuildContext context, {
  required String nickname,
}) async {
  final l10n = L10n.of(context);
  final controller = TextEditingController();

  final message = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        l10n.gardenChatRequestTitle(nickname),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 100,
        maxLines: 3,
        cursorColor: AppColors.moonlight,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: l10n.gardenChatRequestHint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(l10n.commonSend),
        ),
      ],
    ),
  );

  return (message == null || message.isEmpty) ? null : message;
}
