import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../postinfo/data/models/post_info.dart';
import '../../../profile/data/models/profile_catalog.dart';
import '../../data/models/chat_models.dart';
import '../providers/chat_provider.dart';

/// 대화 신청 팝업(기획 4-3 img09).
///
/// 달빛가든 카드 · [포스트 정보] · [프로필 보기]가 같은 팝업을 띄운다.
///
/// 🚨 **숫자를 코드에 굳히지 않는다.** "무료 몇 회 남았는지", "루나 몇 개인지",
/// "몇 자까지인지"는 전부 서버 설정(`app.chat.*`)이고 사람마다 다르다 —
/// 팝업이 열릴 때 물어서(`chatRequestQuotaProvider`) 그 값으로 문장을 만든다.
///
/// 보내는 것까지 하지 않고 **입력받은 한마디만** 돌려준다. 차감·차단 판정은 서버가 한다.
Future<String?> showChatRequestDialog(
  BuildContext context, {
  required PostInfo info,
}) async {
  final message = await showDialog<String>(
    context: context,
    builder: (_) => _ChatRequestDialog(info: info),
  );
  return (message == null || message.isEmpty) ? null : message;
}

/// 보낸 뒤의 안내(기획 4-3 img09 우측).
///
/// 스낵바로 스쳐 보내지 않는 건, 여기서 알려 줄 것이 **결과가 아니라 다음 할 일**이기
/// 때문이다 — 상대의 수락 여부를 어디서 확인하는지.
Future<void> showChatRequestSentDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final l10n = L10n.of(context);
      return Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.moonlightDeep,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppDimens.gapMd),
              Text(
                l10n.gardenChatRequestSentTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDimens.gapSm),
              Text(
                l10n.gardenChatRequestSent,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppDimens.gapMd),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.moonlight,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.gardenChatRequestWhere,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.gapMd),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.moonlightDeep,
                  ),
                  child: Text(l10n.commonConfirm),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ChatRequestDialog extends ConsumerStatefulWidget {
  const _ChatRequestDialog({required this.info});

  final PostInfo info;

  @override
  ConsumerState<_ChatRequestDialog> createState() => _ChatRequestDialogState();
}

class _ChatRequestDialogState extends ConsumerState<_ChatRequestDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final info = widget.info;
    final quota = ref.watch(chatRequestQuotaProvider).valueOrNull;
    final photo = info.profilePhotoUrl;
    final region = info.regions.isEmpty ? null : info.regions.first;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(width: 36),
                  Expanded(
                    child: Text(
                      l10n.gardenChatRequestShort,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: l10n.commonClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.gapSm),

              // 상대 한 줄 — 사진 · 이름 나이 국기 · 지역 · 접속
              Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 62,
                      height: 62,
                      child: photo == null
                          ? const ColoredBox(
                              color: AppColors.surfaceHigh,
                              child: Icon(
                                Icons.person,
                                color: AppColors.textMuted,
                              ),
                            )
                          : AuthedImage(url: photo),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                info.age == null
                                    ? info.nickname
                                    : '${info.nickname} ${info.age}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (info.country != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                ProfileCatalog.countryFlag(info.country!),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                        if (region != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            ProfileCatalog.regionLabel(l10n, region),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: info.online
                                    ? AppColors.line
                                    : AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              info.online
                                  ? l10n.statusOnline
                                  : l10n.statusOffline,
                              style: TextStyle(
                                color: info.online
                                    ? AppColors.line
                                    : AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.gapMd),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: AppDimens.gapMd),

              Text(
                l10n.gardenChatRequestPrompt(info.nickname),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppDimens.gapMd),

              TextField(
                controller: _controller,
                // 한도를 아직 못 받았으면 막지 않는다 — 어차피 서버가 잰다.
                maxLength: quota?.maxLength,
                maxLines: 4,
                minLines: 3,
                cursorColor: AppColors.moonlight,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                buildCounter:
                    (_, {required currentLength, required isFocused, maxLength}) =>
                        Text(
                          maxLength == null
                              ? '$currentLength'
                              : '$currentLength/$maxLength',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                decoration: InputDecoration(
                  hintText: l10n.gardenChatRequestHint,
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.gapSm),
              if (quota != null) _QuotaNotice(quota: quota),

              const SizedBox(height: AppDimens.gapMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _controller.text.trim().isEmpty
                          ? null
                          : () =>
                                Navigator.pop(context, _controller.text.trim()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.moonlightDeep,
                        disabledBackgroundColor: AppColors.surfaceHigh,
                        disabledForegroundColor: AppColors.textMuted,
                      ),
                      child: Text(_buttonLabel(l10n, quota)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `대화 신청 (무료 2회)` / `대화 신청 (★ 5)` / `대화 신청`.
  ///
  /// 무엇이 나갈지를 **누르기 전에** 알려 준다 — 루나가 빠지고 나서 아는 것과는 다르다.
  static String _buttonLabel(L10n l10n, ChatRequestQuota? quota) {
    if (quota == null || quota.unlimited) return l10n.gardenChatRequestShort;
    if (quota.freeRemaining > 0) {
      return l10n.gardenChatRequestFree(quota.freeRemaining);
    }
    return l10n.gardenChatRequestCost(quota.lunaCost);
  }
}

/// 무료 횟수·루나·프라임 안내 상자(시안의 달 아이콘 상자).
class _QuotaNotice extends StatelessWidget {
  const _QuotaNotice({required this.quota});

  final ChatRequestQuota quota;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.moonlight.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.nightlight_round,
            color: AppColors.gold,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quota.unlimited
                      ? l10n.gardenChatRequestUnlimited
                      : l10n.gardenChatRequestFreeNotice(quota.freePerDay),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                if (!quota.unlimited) ...[
                  Text(
                    l10n.gardenChatRequestCostNotice(quota.lunaCost),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    l10n.gardenChatRequestPrimeNotice,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
