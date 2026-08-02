import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../data/models/friend_models.dart';

/// 친구의 오늘 포스트. (기획서 화면 19)
///
/// 친구 카드를 누르면 뜬다. 여기서 바로 대화방으로 들어갈 수 있다.
class FriendPostSheet extends ConsumerStatefulWidget {
  const FriendPostSheet({
    super.key,
    required this.friend,
    required this.onOpenChat,
  });

  final Friend friend;

  /// 메시지 버튼 — 상시 대화방으로 이동.
  final VoidCallback onOpenChat;

  static Future<void> show(
    BuildContext context, {
    required Friend friend,
    required VoidCallback onOpenChat,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            FriendPostSheet(friend: friend, onOpenChat: onOpenChat),
      );

  @override
  ConsumerState<FriendPostSheet> createState() => _FriendPostSheetState();
}

class _FriendPostSheetState extends ConsumerState<FriendPostSheet> {
  late Future<FriendPost> _future;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _future =
        ref.read(friendApiProvider).todayPost(widget.friend.friendshipId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.pagePad),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: BoxDecoration(
          color: AppColors.night,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            Flexible(
              child: FutureBuilder<FriendPost>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.moonlight,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _Message(
                      // 아직 공유 전이면 서버가 404 + 안내 문구를 준다.
                      text: snapshot.error is ApiException
                          ? (snapshot.error as ApiException).message
                          : '포스트를 불러오지 못했어요.',
                      onOpenChat: widget.onOpenChat,
                    );
                  }
                  return _Content(
                    post: snapshot.data!,
                    index: _index,
                    onIndexChanged: (i) => setState(() => _index = i),
                    onOpenChat: widget.onOpenChat,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: onClose,
          ),
          const Expanded(
            child: Text(
              '오늘의 포스트',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.post,
    required this.index,
    required this.onIndexChanged,
    required this.onOpenChat,
  });

  final FriendPost post;
  final int index;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final photos = post.photoUrls;
    final hasPhoto = photos.isNotEmpty;
    // 사진이 없으면 clamp 상한이 -1이 되어 ArgumentError가 난다(함정 #17).
    final current = hasPhoto ? index.clamp(0, photos.length - 1) : 0;

    return SingleChildScrollView(
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
              Flexible(
                child: Text(
                  post.age == null
                      ? post.nickname
                      : '${post.nickname} ${post.age}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (post.flag.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(post.flag, style: const TextStyle(fontSize: 18)),
              ],
              if (post.pick) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PICK',
                    style: TextStyle(
                      color: Color(0xFF2A2000),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (hasPhoto && photos.length > 1)
                Row(
                  children: List.generate(photos.length, (i) {
                    final active = i == current;
                    return Container(
                      width: active ? 16 : 8,
                      height: 4,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.moonlight
                            : AppColors.textMuted.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.gapSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: AspectRatio(
              aspectRatio: 0.86,
              child: hasPhoto
                  // 좌/우 탭으로 사진을 넘긴다(홈 포스트와 같은 조작).
                  ? GestureDetector(
                      onTapUp: (details) {
                        final width = context.size?.width ?? 1;
                        final next = details.localPosition.dx > width / 2
                            ? current + 1
                            : current - 1;
                        onIndexChanged(next.clamp(0, photos.length - 1));
                      },
                      child: AuthedImage(url: photos[current]),
                    )
                  : const ColoredBox(
                      color: AppColors.surface,
                      child: Center(
                        child: Icon(
                          Icons.photo_outlined,
                          color: AppColors.textMuted,
                          size: 48,
                        ),
                      ),
                    ),
            ),
          ),
          if (post.oneLiner != null && post.oneLiner!.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gapMd),
            Text(
              post.oneLiner!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: AppDimens.gapMd),
          Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xFFE85D6E), size: 22),
              const SizedBox(width: 6),
              Text(
                '${post.likes}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.chat_bubble_outline,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 6),
              Text(
                '${post.comments}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.moonlight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onOpenChat();
                },
                icon: const Icon(Icons.mail_outline, size: 18),
                label: const Text('메시지'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 아직 공유 전이거나 오류일 때. 대화는 여전히 걸 수 있게 버튼은 남긴다.
class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onOpenChat});

  final String text;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePad,
        30,
        AppDimens.pagePad,
        AppDimens.gapLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nightlight_round,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: AppDimens.gapMd),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimens.gapLg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.moonlight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onOpenChat();
              },
              icon: const Icon(Icons.mail_outline, size: 18),
              label: const Text('메시지 보내기'),
            ),
          ),
        ],
      ),
    );
  }
}
