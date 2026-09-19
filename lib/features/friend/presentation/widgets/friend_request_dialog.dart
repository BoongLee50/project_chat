import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/request_message_input.dart';
import '../../../postinfo/data/models/post_info.dart';
import '../../../profile/data/models/profile_catalog.dart';

/// 친구 신청과 함께 보내는 한마디(기획 5-1 img13 좌측).
///
/// **길이는 서버가 잰다**(`app.friend.request-message-max-length`).
/// 🚨 대화 신청과 **같은 규칙**이다(기획사항 2026-09-19 — 100자 통일 · 줄바꿈 불가 ·
/// 공백·이모지·특수문자도 한 글자). 입력 규칙은 [RequestMessageInput] 한 곳에 있다.
///
/// 비워도 보낼 수 있다 — 시안이 `(선택)`이라고 적어 두었다.
/// 취소하면 null, 보내면 (빈 문자열일 수도 있는) 한마디를 돌려준다.
Future<String?> showFriendRequestDialog(
  BuildContext context, {
  required PostInfo info,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _FriendRequestDialog(info: info),
  );
}

/// 받은 친구 신청(기획 5-1 img13 우측). 수락하면 true, 거절하면 false.
Future<bool?> showIncomingFriendRequestDialog(
  BuildContext context, {
  required PostInfo info,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _IncomingFriendRequestDialog(info: info),
  );
}

const int _maxLength = RequestMessageInput.defaultMax;

class _FriendRequestDialog extends StatefulWidget {
  const _FriendRequestDialog({required this.info});

  final PostInfo info;

  @override
  State<_FriendRequestDialog> createState() => _FriendRequestDialogState();
}

class _FriendRequestDialogState extends State<_FriendRequestDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 남은 글자 수를 세야 하므로 입력이 바뀔 때마다 다시 그린다.
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

    return _DialogShell(
      title: l10n.friendRequestTitle,
      info: widget.info,
      children: [
        Text(
          l10n.friendRequestPrompt(widget.info.nickname, _maxLength),
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
          // `maxLength`는 글자 모양 단위라 서버(코드포인트)와 어긋난다 — 규칙으로 막는다.
          inputFormatters: RequestMessageInput.formatters(_maxLength),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          // 25자 → 100자가 되며 두 줄로는 모자라 네 줄까지 접히게 했다(줄바꿈은 여전히 불가).
          maxLines: 4,
          minLines: 2,
          cursorColor: AppColors.moonlight,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            counterText:
                '${RequestMessageInput.length(_controller.text)}/$_maxLength',
            counterStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
            hintText: l10n.friendRequestHint,
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
        Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 14,
              color: AppColors.moonlight,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.friendRequestNotice,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gapMd),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.commonClose),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(context, _controller.text.trim()),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: Text(l10n.friendRequestTitle),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moonlightDeep,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IncomingFriendRequestDialog extends StatelessWidget {
  const _IncomingFriendRequestDialog({required this.info});

  final PostInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return _DialogShell(
      title: l10n.friendRequestIncomingTitle,
      info: info,
      children: [
        Text(
          l10n.friendRequestIncomingBody(info.nickname),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppDimens.gapLg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.commonReject),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moonlightDeep,
                ),
                child: Text(l10n.postInfoFriendIncoming),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 두 팝업이 공유하는 껍데기 — 제목 · ✕ · 상대 한 줄(사진·이름·지역·접속).
class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.title,
    required this.info,
    required this.children,
  });

  final String title;
  final PostInfo info;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final photo = info.profilePhotoUrl;
    final region = info.regions.isEmpty ? null : info.regions.first;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
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
                    title,
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
            Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 66,
                    height: 66,
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
            ...children,
          ],
        ),
      ),
    );
  }
}
