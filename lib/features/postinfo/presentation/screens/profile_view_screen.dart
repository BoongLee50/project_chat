import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/session_provider.dart';
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
    // `[원문보기]`는 **상대와 내 나라가 다를 때만 눌린다** — 같으면 흐리게 자리만(2026-10-05).
    // 어느 한쪽 나라를 모르면 누를 수 있게 둔다(못 누르는 이유를 댈 수 없다).
    final myCountry = ref.watch(sessionProvider).profile?.country;
    final partnerCountry = _info.country;
    final viewOriginalEnabled = myCountry == null || partnerCountry == null
        ? true
        : myCountry != partnerCountry;

    return ProfilePreviewView(
      viewOriginalEnabled: viewOriginalEnabled,
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
      // 하단 버튼은 **관계가 정한다**(2026-10-05 사용자 결정) — 버튼이 없으면 자리도 없다.
      bottom: switch (profileViewActionOf(
        _info,
        myUserId: ref.watch(sessionProvider).profile?.id,
      )) {
        ProfileViewAction.none => null,
        final action => _Action(
          action: action,
          onRequestChat: _requestChat,
          onRequestFriend: _requestFriend,
        ),
      },
    );
  }
}

/// [프로필 보기] 하단에 무엇을 둘까 — 남의 프로필에서만 쓴다(내 [미리 보기]에는 하단이 없다).
enum ProfileViewAction {
  /// 버튼 없음.
  none,

  /// [대화 신청]
  requestChat,

  /// [친구 신청]
  requestFriend,

  /// [친구 신청]을 이미 보냈다 — 같은 자리에 `신청 대기`를 흐리게(막힌 버튼은 이유를 말한다).
  friendPending,
}

/// 하단 버튼 규칙(2026-10-05 사용자 결정). **위에서부터 먼저 맞는 것**이 이긴다.
///
/// | 상대와 나 | 하단 |
/// |---|---|
/// | 나 자신(가든 댓글 작성자가 나일 때 등) | 없음 |
/// | 이미 **친구** | 없음 |
/// | 상대가 나에게 **대화 신청**을 보냈다(대화방 [받은 신청] 목록에 있다) | 없음 — 답은 받은 신청에서 한다 |
/// | **대화 중**인데 친구가 아니다 | [친구 신청] (내가 이미 보냈으면 `신청 대기`) |
/// | 아무 관계도 아니다 | [대화 신청] |
///
/// 📌 대화 중에 **상대가 먼저 친구 신청**을 보낸 경우는 표에 없어 [친구 신청]을 그대로 둔다 —
/// 누르면 서버가 `FRIEND_REQUEST_PENDING`으로 이유를 말한다. 내가 보낸 대화 신청이 아직
/// 답을 기다리는 경우도 [대화 신청]이 남고, 누르면 서버가 이유를 말한다.
ProfileViewAction profileViewActionOf(PostInfo info, {String? myUserId}) {
  final self = myUserId != null && info.userId == myUserId;
  if (self ||
      info.friendRelation == FriendRelation.friend ||
      info.chatRequestId != null) {
    return ProfileViewAction.none;
  }
  if (info.chatRoomId != null) {
    return info.friendRelation == FriendRelation.requested
        ? ProfileViewAction.friendPending
        : ProfileViewAction.requestFriend;
  }
  return ProfileViewAction.requestChat;
}

/// 하단 버튼 한 칸 — 무엇을 둘지는 [profileViewActionOf]가 정한다.
class _Action extends StatelessWidget {
  const _Action({
    required this.action,
    required this.onRequestChat,
    required this.onRequestFriend,
  });

  final ProfileViewAction action;
  final VoidCallback onRequestChat;
  final VoidCallback onRequestFriend;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final chat = action == ProfileViewAction.requestChat;

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
            onPressed: switch (action) {
              ProfileViewAction.requestChat => onRequestChat,
              ProfileViewAction.requestFriend => onRequestFriend,
              _ => null,
            },
            icon: Icon(
              chat
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.person_add_alt_1_outlined,
              size: 18,
            ),
            label: Text(switch (action) {
              ProfileViewAction.friendPending => l10n.postInfoFriendPending,
              ProfileViewAction.requestFriend => l10n.postInfoFriendAdd,
              _ => l10n.postInfoRequestChat,
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
