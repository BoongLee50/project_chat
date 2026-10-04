import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/presentation/widgets/chat_request_dialog.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../../friend/presentation/widgets/friend_request_dialog.dart';
import '../../../profile/presentation/widgets/profile_preview_view.dart';
import '../../data/models/post_info.dart';
import '../providers/post_info_provider.dart';

/// [프로필 보기] — 상대의 **프로필 창**. 대화방·친구·가든의 [프로필] 버튼이 연다.
///
/// 🚨 **내 [미리 보기]와 같은 창이다**(기획 2026-10-04 — "다른 유저가 나의 프로필을 눌렀을 때도
/// 출력되는 창"). 그래서 그림은 프로필 쪽 [ProfilePreviewView] 하나를 함께 쓰고,
/// 여기는 **남의 것일 때만 붙는 하단 버튼**([대화 신청]/[친구 신청])만 더한다.
/// - 사진: **프로필 사진**(포스트 사진이 아니다) → 열람 제한과 무관하다
Future<void> showProfileView(BuildContext context, String targetUserId) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ProfileViewScreen(targetUserId: targetUserId),
      fullscreenDialog: true,
    ),
  );
}

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key, required this.targetUserId});

  final String targetUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final info = ref.watch(postInfoProvider(targetUserId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: info.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (_, _) => SafeArea(
          child: Stack(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: l10n.commonBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: ProfilePreviewView.ink,
                ),
              ),
              Center(
                child: Text(
                  l10n.postInfoLoadFailed,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (data) => _Body(info: data),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.info});

  final PostInfo info;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  PostInfo get _info => widget.info;

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestChat() async {
    final l10n = L10n.of(context);
    final message = await showChatRequestDialog(context, info: _info);
    if (message == null || !mounted) return;
    final error = await ref
        .read(chatActionsProvider)
        .requestChat(_info.userId, message);
    if (!mounted) return;
    if (error != null) {
      _toast(errorMessage(l10n, error));
      return;
    }
    await showChatRequestSentDialog(context);
  }

  /// 친구 신청 — 한마디(100자)를 함께 보낸다. 비워도 보낼 수 있다.
  Future<void> _requestFriend() async {
    final l10n = L10n.of(context);
    final message = await showFriendRequestDialog(context, info: _info);
    if (message == null || !mounted) return;

    final error = await ref
        .read(friendActionsProvider)
        .request(_info.userId, message: message.isEmpty ? null : message);
    if (!mounted) return;
    _toast(error == null ? l10n.friendsRequestSent : errorMessage(l10n, error));
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePreviewView(
      data: ProfilePreviewData(
        nickname: _info.nickname,
        age: _info.age,
        country: _info.country,
        facePhotoUrl: _info.profilePhotoUrl,
        mainPhotoUrl: _info.profileMainPhotoUrl,
        intro: _info.intro,
        interests: _info.interests,
        regions: _info.regions,
      ),
      bottom: _Action(
        info: _info,
        onRequestChat: _requestChat,
        onRequestFriend: _requestFriend,
      ),
    );
  }
}

/// 하단 버튼 — [포스트 정보]와 같은 원칙: **지금 상태가 정한다**.
///
/// 시안(img12)은 `[대화 신청]`과 `[친구 신청]`을 화살표로 이어 두 가지가 번갈아
/// 들어감을 보인다. 무엇이 들어갈지는 부르는 화면이 아니라 관계가 정한다 —
/// 아직 말을 안 텄으면 대화부터, 이미 대화 중이면 친구.
class _Action extends StatelessWidget {
  const _Action({
    required this.info,
    required this.onRequestChat,
    required this.onRequestFriend,
  });

  final PostInfo info;
  final VoidCallback onRequestChat;
  final VoidCallback onRequestFriend;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    // 이미 친구이거나 답을 기다리는 중이면 누를 것이 없다.
    final settled =
        info.friendRelation == FriendRelation.friend ||
        info.friendRelation == FriendRelation.requested;
    final chatting = info.chatRoomId != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gapMd,
          AppDimens.gapSm,
          AppDimens.gapMd,
          AppDimens.gapSm,
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: settled
                ? null
                : (chatting ? onRequestFriend : onRequestChat),
            icon: Icon(
              chatting
                  ? Icons.person_add_alt_1_outlined
                  : Icons.chat_bubble_outline_rounded,
              size: 18,
            ),
            label: Text(switch (info.friendRelation) {
              FriendRelation.friend => l10n.postInfoFriendLabel,
              FriendRelation.requested => l10n.postInfoFriendPending,
              _ => chatting ? l10n.postInfoFriendAdd : l10n.postInfoRequestChat,
            }),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.moonlightDeep,
              disabledBackgroundColor: AppColors.surfaceHigh,
              disabledForegroundColor: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
