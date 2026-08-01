import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../data/models/feed_item.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../providers/garden_provider.dart';
import '../widgets/comments_sheet.dart';

/// 달빛가든 — 포스트 사진 피드. 메인 셸의 '달빛가든' 탭 본문. (기획서 4장)
///
/// 필터(성별·연령대·국가)·스포트라이트·좋아요·스킵(스와이프)·댓글을 서버와 연동한다.
/// 대화 신청은 chat 도메인 구현 후 연결 예정.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePad,
        AppDimens.gapMd,
        AppDimens.pagePad,
        AppDimens.gapMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GardenHeader(),
          const SizedBox(height: AppDimens.gapMd),
          const _FilterBar(),
          const SizedBox(height: AppDimens.gapMd),
          Expanded(
            child: feed.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.moonlight),
              ),
              error: (error, _) => _Message(
                icon: Icons.cloud_off,
                title: '피드를 불러오지 못했어요.',
                detail: '$error',
                onRetry: () => ref.read(feedProvider.notifier).refresh(),
              ),
              data: (items) => items.isEmpty
                  ? _Message(
                      icon: Icons.nightlight_round,
                      title: '지금은 보여줄 포스트가 없어요.',
                      detail: '필터를 바꾸거나 잠시 후 다시 확인해 주세요.',
                      onRetry: () => ref.read(feedProvider.notifier).refresh(),
                    )
                  : _FeedPager(items: items),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 헤더 ─────────────────────────────────────────────────
class _GardenHeader extends StatelessWidget {
  const _GardenHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    '달빛가든',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.nightlight_round,
                    color: AppColors.moonlight,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '달빛 아래, 우리의 하루를 나누는 공간 ✨',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.textPrimary,
          size: 26,
        ),
        const SizedBox(width: 16),
        const Icon(Icons.tune_rounded, color: AppColors.textPrimary, size: 26),
      ],
    );
  }
}

// ── 필터 바 ──────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(feedFilterProvider);
    final controller = ref.read(feedFilterProvider.notifier);
    final spotlight = ref.watch(spotlightProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterMenu<String>(
            label: filter.gender == null
                ? '전체'
                : (filter.gender == 'FEMALE' ? '여자' : '남자'),
            icon: Icons.wc,
            selected: filter.gender != null,
            options: const {'전체': null, '여자': 'FEMALE', '남자': 'MALE'},
            current: filter.gender,
            onPick: (value) => value == null
                ? controller.toggleGender(filter.gender ?? '')
                : controller.toggleGender(value),
          ),
          const SizedBox(width: 8),
          _FilterMenu<int>(
            label: filter.ageDecade == null ? '전체' : '${filter.ageDecade}대',
            icon: Icons.person_outline,
            selected: filter.ageDecade != null,
            options: const {
              '전체': null,
              '10대': 10,
              '20대': 20,
              '30대': 30,
              '40대': 40,
            },
            current: filter.ageDecade,
            onPick: (value) => value == null
                ? controller.toggleAge(filter.ageDecade ?? -1)
                : controller.toggleAge(value),
          ),
          const SizedBox(width: 8),
          _FilterMenu<String>(
            label: filter.country == null
                ? '전체'
                : (filter.country == 'KR' ? '한국' : '일본'),
            icon: Icons.public,
            selected: filter.country != null,
            options: const {'전체': null, '한국': 'KR', '일본': 'JP'},
            current: filter.country,
            onPick: (value) => value == null
                ? controller.toggleCountry(filter.country ?? '')
                : controller.toggleCountry(value),
          ),
          const SizedBox(width: 8),
          _SpotlightChip(
            active: spotlight,
            onTap: () =>
                ref.read(spotlightProvider.notifier).state = !spotlight,
          ),
        ],
      ),
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.icon,
    required this.selected,
    required this.options,
    required this.current,
    required this.onPick,
  });

  final String label;
  final IconData icon;
  final bool selected;

  /// 표시명 → 값(전체는 null)
  final Map<String, T?> options;
  final T? current;
  final ValueChanged<T?> onPick;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.surfaceHigh,
      onSelected: (name) => onPick(options[name]),
      itemBuilder: (context) => [
        for (final entry in options.entries)
          PopupMenuItem(
            value: entry.key,
            child: Text(
              entry.key,
              style: TextStyle(
                color: entry.value == current
                    ? AppColors.moonlight
                    : AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.moonlight.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.moonlight : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.moonlight : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightChip extends StatelessWidget {
  const _SpotlightChip({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: active
              ? const LinearGradient(
                  colors: [AppColors.moonlightDeep, AppColors.moonlight],
                )
              : null,
          border: active ? null : Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: active ? Colors.white : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              '스포트라이트',
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 피드 카드 ────────────────────────────────────────────
/// 좌우 스와이프로 스킵하며 다음 카드로 넘어간다(기획서 4-1).
class _FeedPager extends ConsumerStatefulWidget {
  const _FeedPager({required this.items});

  final List<FeedItem> items;

  @override
  ConsumerState<_FeedPager> createState() => _FeedPagerState();
}

class _FeedPagerState extends ConsumerState<_FeedPager> {
  int _photoIndex = 0;

  FeedItem get _item => widget.items.first;

  Future<void> _skip() async {
    // Dismissible이 위젯을 제거한 뒤 async가 이어지므로,
    // await 이전에 notifier를 확보해 둔다(dispose 후 ref 사용 방지).
    final notifier = ref.read(feedProvider.notifier);
    final nearlyEmpty = widget.items.length <= 2;
    _photoIndex = 0;

    final error = await notifier.skip(_item);
    if (error != null && mounted) _toast(error);
    // 목록이 얼마 안 남으면 다음 페이지를 이어붙인다.
    if (nearlyEmpty) notifier.loadMore();
  }

  Future<void> _like() async {
    final error = await ref.read(feedProvider.notifier).like(_item);
    if (error != null && mounted) _toast(error);
  }

  /// 대화 신청 팝업 — 하루 무료 2회 후 루나 5 차감(서버 판정).
  Future<void> _requestChat(FeedItem item) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          '${item.nickname}님에게 대화 신청',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          maxLines: 3,
          cursorColor: AppColors.moonlight,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '첫 인사를 남겨보세요 (최대 100자)',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('보내기'),
          ),
        ],
      ),
    );

    if (message == null || message.isEmpty || !mounted) return;
    final error = await ref
        .read(chatActionsProvider)
        .requestChat(item.userId, message);
    if (!mounted) return;
    _toast(error ?? '대화 신청을 보냈어요. 상대의 응답을 기다려 주세요.');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final photos = item.photoUrls;
    final index = photos.isEmpty ? 0 : _photoIndex.clamp(0, photos.length - 1);
    // 사진을 넘겨 보는 중에는 하루 한마디 대신 관심사를 노출(기획서 4-1).
    final showInterests = index > 0 && item.interests.isNotEmpty;

    return Dismissible(
      key: ValueKey(item.userId),
      onDismissed: (_) => _skip(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photos.isEmpty)
              const ColoredBox(color: AppColors.surface)
            else
              GestureDetector(
                onTapUp: (details) {
                  final width = context.size?.width ?? 1;
                  final next = details.localPosition.dx > width / 2
                      ? index + 1
                      : index - 1;
                  setState(
                    () => _photoIndex = next.clamp(0, photos.length - 1),
                  );
                },
                child: AuthedImage(url: photos[index]),
              ),

            // 가독성 스크림
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xE6000000),
                  ],
                  stops: [0.0, 0.22, 0.5, 1.0],
                ),
              ),
            ),

            // 상단: 이름 · 국기 · PICK · 접속중
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      [item.nickname, if (item.age != null) '${item.age}']
                          .join(' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (item.flag.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(item.flag, style: const TextStyle(fontSize: 20)),
                  ],
                  if (item.pick) ...[
                    const SizedBox(width: 8),
                    const _PickBadge(),
                  ],
                  if (item.online) ...[
                    const SizedBox(width: 8),
                    const _OnlineBadge(),
                  ],
                  const Spacer(),
                  if (photos.length > 1)
                    Row(
                      children: List.generate(
                        photos.length,
                        (i) => Container(
                          width: 16,
                          height: 3,
                          margin: const EdgeInsets.only(left: 4),
                          color: Colors.white.withValues(
                            alpha: i == index ? 0.9 : 0.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 하단: 한마디(또는 관심사) + 좋아요/댓글/메시지
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showInterests)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final code in item.interests)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Text(
                      item.oneLiner ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _IconCount(
                        icon: Icons.favorite,
                        color: const Color(0xFFE85D6E),
                        label: '${item.likes}',
                        onTap: _like,
                      ),
                      const SizedBox(width: 20),
                      _IconCount(
                        icon: Icons.chat_bubble_outline,
                        color: Colors.white,
                        label: '${item.comments}',
                        onTap: () => showCommentsSheet(context, item),
                      ),
                      const Spacer(),
                      // 대화 신청 — 100자 메시지를 적어 보낸다(기획서 4-3)
                      GestureDetector(
                        onTap: () => _requestChat(item),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mail_outline,
                            color: Color(0xFF2A2400),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconCount extends StatelessWidget {
  const _IconCount({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickBadge extends StatelessWidget {
  const _PickBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'PICK',
        style: TextStyle(
          color: Color(0xFF2A2400),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.circle, color: Color(0xFF3FCF6B), size: 8),
          SizedBox(width: 4),
          Text(
            '접속 중',
            style: TextStyle(color: Color(0xFF3FCF6B), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.pagePad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
