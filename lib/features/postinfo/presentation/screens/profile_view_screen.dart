import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/presentation/widgets/chat_request_dialog.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../../friend/presentation/widgets/friend_request_dialog.dart';
import '../../../profile/data/models/profile_catalog.dart';
import '../../data/models/post_info.dart';
import '../providers/post_info_provider.dart';
import '../widgets/info_cards.dart';

/// [프로필 보기] — 상대의 **프로필**을 보는 풀스크린(기획 5장 img12 좌측).
///
/// [포스트 정보]와 닮았지만 보는 것이 다르다.
/// - 사진: **프로필 사진**(포스트 사진이 아니다) → 열람 제한과 무관하다
/// - 카드: 관심사 · 소개 한마디 · **활동 지역**(포스트 정보에는 없다)
/// - 하단: 아직 대화 전이면 `[대화 신청]`, 대화 중이면 `[친구 신청]`
///
/// 채팅창 ⋯ 메뉴와 [포스트 정보] ⋯ 메뉴가 같은 화면을 연다.
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
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: AppColors.night,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: l10n.commonBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: info.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (_, _) => Center(
          child: Text(
            l10n.postInfoLoadFailed,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
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

  /// 친구 신청 — 한마디(25자)를 함께 보낸다(V17). 비워도 보낼 수 있다.
  Future<void> _requestFriend() async {
    final l10n = L10n.of(context);
    final message = await showFriendRequestDialog(context, info: _info);
    if (message == null || !mounted) return;

    final error = await ref
        .read(friendActionsProvider)
        .request(_info.userId, message: message.isEmpty ? null : message);
    if (!mounted) return;
    _toast(
      error == null ? l10n.friendsRequestSent : errorMessage(l10n, error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final photo = _info.profilePhotoUrl;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gapMd,
              0,
              AppDimens.gapMd,
              AppDimens.gapMd,
            ),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                child: AspectRatio(
                  aspectRatio: 0.92,
                  child: photo == null
                      ? const ColoredBox(
                          color: AppColors.surfaceHigh,
                          child: Icon(
                            Icons.person,
                            color: AppColors.textMuted,
                            size: 56,
                          ),
                        )
                      : AuthedImage(url: photo),
                ),
              ),
              const SizedBox(height: AppDimens.gapMd),
              _NameRow(info: _info),
              const SizedBox(height: AppDimens.gapMd),

              if (_info.interests.isNotEmpty)
                InfoCard(
                  icon: Icons.favorite_border_rounded,
                  title: l10n.profileInterests,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final code in _info.interests)
                        InfoChip(
                          label: ProfileCatalog.interestLabel(l10n, code),
                        ),
                    ],
                  ),
                ),

              if (_info.intro != null && _info.intro!.isNotEmpty)
                InfoCard(
                  icon: Icons.format_quote_rounded,
                  title: l10n.profileIntro,
                  child: Text(
                    _info.intro!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),

              // 활동 지역은 **[프로필 보기]에만** 있다(시안 img12). 포스트 정보는
              // 오늘 올린 것을 보는 자리라 사는 곳을 묻지 않는다.
              if (_info.regions.isNotEmpty)
                InfoCard(
                  icon: Icons.place_outlined,
                  title: l10n.profileRegions,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final code in _info.regions)
                        InfoChip(
                          label: ProfileCatalog.regionLabel(l10n, code),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _Action(
          info: _info,
          onRequestChat: _requestChat,
          onRequestFriend: _requestFriend,
        ),
      ],
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.info});

  final PostInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            info.age == null ? info.nickname : '${info.nickname} ${info.age}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (info.country != null) ...[
          const SizedBox(width: 8),
          Text(
            ProfileCatalog.countryFlag(info.country!),
            style: const TextStyle(fontSize: 17),
          ),
        ],
        if (info.online) ...[
          const SizedBox(width: 10),
          const OnlineDot(size: 8),
          const SizedBox(width: 4),
          Text(
            l10n.commonOnline,
            style: const TextStyle(
              color: AppColors.line,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
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
    final settled = info.friendRelation == FriendRelation.friend ||
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
            label: Text(
              switch (info.friendRelation) {
                FriendRelation.friend => l10n.postInfoFriendLabel,
                FriendRelation.requested => l10n.postInfoFriendPending,
                _ => chatting
                    ? l10n.postInfoFriendAdd
                    : l10n.postInfoRequestChat,
              },
            ),
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
