import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/providers.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../data/models/my_post.dart';
import '../providers/post_provider.dart';

/// 홈 — 오늘의 포스트. 메인 셸의 '포스트' 탭 본문. (기획서 3장, 01 문서 §1.3)
///
/// 사진 등록/삭제, 하루 한 마디, 공유하기를 서버와 연동한다.
/// 루나 잔액·달 위상·좋아요/댓글 수치는 해당 도메인(luna/garden) 구현 후 연결 예정.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postState = ref.watch(myPostProvider);

    return RefreshIndicator(
      color: AppColors.moonlight,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(myPostProvider.notifier).refresh(),
      child: postState.when(
        loading: () => const _CenteredScroll(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (error, _) => _CenteredScroll(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.pagePad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: AppColors.textMuted,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  '포스트를 불러오지 못했어요.',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '아래로 당겨 새로고침해 주세요.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (post) => _PostBody(post: post),
      ),
    );
  }
}

/// RefreshIndicator가 동작하려면 항상 스크롤 가능해야 한다.
class _CenteredScroll extends StatelessWidget {
  const _CenteredScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _PostBody extends ConsumerWidget {
  const _PostBody({required this.post});

  final MyPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePad,
        AppDimens.gapMd,
        AppDimens.pagePad,
        AppDimens.gapMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TopBar(),
          const SizedBox(height: AppDimens.gapMd),
          _InfoCards(post: post),
          const SizedBox(height: AppDimens.gapMd),
          _PostPhotoCard(post: post),
          const SizedBox(height: AppDimens.gapMd),
          const _NameLikeRow(),
          const SizedBox(height: AppDimens.gapLg),
          _OneLiner(post: post),
          const SizedBox(height: AppDimens.gapLg),
          _ShareButton(post: post),
        ],
      ),
    );
  }
}

// ── 상단 바 ──────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '오늘의 포스트',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.moonlight,
            shape: BoxShape.circle,
          ),
        ),
        const Spacer(),
        // 보유 루나 — luna 도메인 구현 후 실제 잔액 연결 예정.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.moonlight),
          ),
          child: Row(
            children: const [
              Icon(Icons.star_rounded, color: AppColors.gold, size: 22),
              SizedBox(width: 8),
              Text(
                '—',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 달 정보 / 남은 시간 카드 ─────────────────────────────
class _InfoCards extends StatelessWidget {
  const _InfoCards({required this.post});

  final MyPost post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            child: Row(
              children: const [
                Icon(Icons.nightlight_round, color: AppColors.gold, size: 30),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '오늘의 달',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    // 달 위상은 별도 이벤트 테이블 예정(기획서 3-1).
                    Text(
                      '초승달',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimens.gapMd),
        Expanded(
          child: _InfoCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '포스트 등록 남은 시간',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _remainingLabel(post),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 프라임/앨범패스는 시간 제한이 없어 "PASS"로 표시한다(기획서 3-1).
  static String _remainingLabel(MyPost post) {
    if (post.uploadUnlimited) return 'PASS';
    if (!post.gateOpen) return '--:--';
    final seconds = post.remainingUploadSeconds ?? 0;
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.moonlight.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}

// ── 포스트 사진 카드 ─────────────────────────────────────
class _PostPhotoCard extends ConsumerStatefulWidget {
  const _PostPhotoCard({required this.post});

  final MyPost post;

  @override
  ConsumerState<_PostPhotoCard> createState() => _PostPhotoCardState();
}

class _PostPhotoCardState extends ConsumerState<_PostPhotoCard> {
  int _index = 0;
  bool _busy = false;

  List<PostPhoto> get _photos => widget.post.photos;

  /// 카메라로 촬영해 업로드. 갤러리 선택은 앨범 패스 보유자만(기획서 3-1).
  Future<void> _capture() async {
    if (_busy) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _busy = true);
    final bytes = await file.readAsBytes();
    final error = await ref.read(myPostProvider.notifier).addPhoto(bytes);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) _toast(error);
  }

  Future<void> _delete() async {
    if (_busy || _photos.isEmpty) return;
    setState(() => _busy = true);
    final target = _photos[_index.clamp(0, _photos.length - 1)];
    final error = await ref.read(myPostProvider.notifier).deletePhoto(target.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _index = 0;
    });
    if (error != null) _toast(error);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final headers = ref.watch(authHeadersProvider).valueOrNull ?? const {};
    final hasPhoto = _photos.isNotEmpty;
    final index = _index.clamp(0, _photos.length - 1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: AspectRatio(
        aspectRatio: 0.86,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              // 좌/우 탭으로 등록된 사진을 순차 검색(기획서 3-1).
              GestureDetector(
                onTapUp: (details) {
                  final width = context.size?.width ?? 1;
                  final next = details.localPosition.dx > width / 2
                      ? index + 1
                      : index - 1;
                  setState(
                    () => _index = next.clamp(0, _photos.length - 1),
                  );
                },
                child: _AuthedImage(
                  url: _photos[index].url,
                  headers: headers,
                ),
              )
            else
              const _EmptyPhoto(),

            if (_busy)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  color: AppColors.moonlight,
                ),
              ),

            // 삭제 버튼
            if (hasPhoto)
              Positioned(
                left: 14,
                bottom: 14,
                child: _RoundButton(
                  icon: Icons.delete_outline,
                  background: Colors.black.withValues(alpha: 0.5),
                  iconColor: AppColors.textPrimary,
                  size: 44,
                  onTap: _delete,
                ),
              ),

            // 촬영 버튼 — 등록 가능 시간/장수를 넘기면 비활성
            Align(
              alignment: const Alignment(0, 0.92),
              child: _RoundButton(
                icon: Icons.photo_camera_rounded,
                background: widget.post.canAddPhoto
                    ? AppColors.moonlight
                    : AppColors.surfaceHigh,
                iconColor: widget.post.canAddPhoto
                    ? Colors.white
                    : AppColors.textMuted,
                size: 60,
                onTap: widget.post.canAddPhoto ? _capture : null,
              ),
            ),

            // 페이지 인디케이터(등록된 사진 수 기준)
            if (hasPhoto)
              Positioned(
                right: 16,
                bottom: 24,
                child: Row(
                  children: List.generate(_photos.length, (i) {
                    final active = i == index;
                    return Container(
                      width: active ? 18 : 8,
                      height: 6,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.moonlight
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 인증이 필요한 이미지(`GET /files?key=`) 로더.
class _AuthedImage extends StatelessWidget {
  const _AuthedImage({required this.url, required this.headers});

  final String url;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    if (headers.isEmpty) {
      return const ColoredBox(color: AppColors.surface);
    }
    return Image.network(
      _absolute(url),
      fit: BoxFit.cover,
      headers: headers,
      errorBuilder: (_, _, _) => const _EmptyPhoto(),
    );
  }

  /// 서버는 상대 경로(`/files?key=...`)를 주므로 base URL을 붙인다.
  static String _absolute(String url) {
    if (url.startsWith('http')) return url;
    return '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080')}$url';
  }
}

class _EmptyPhoto extends ConsumerWidget {
  const _EmptyPhoto();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(sessionProvider).profile?.nickname ?? '';
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppDimens.pagePad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.nightlight_round,
            color: AppColors.moonlight,
            size: 44,
          ),
          const SizedBox(height: 14),
          Text(
            '$nickname님',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '달빛 아래의 지금을 포스트해 보세요.\n새로운 대화의 시작이 될 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.size,
    this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: size * 0.5),
        ),
      ),
    );
  }
}

// ── 이름 + 좋아요/댓글 ───────────────────────────────────
class _NameLikeRow extends ConsumerWidget {
  const _NameLikeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 이름·나이·국가는 내 프로필(GET /me) 기준.
    // 좋아요/댓글 수치는 garden 도메인 구현 후 연결 예정.
    final profile = ref.watch(sessionProvider).profile;
    final age = profile?.birthYear == null
        ? null
        : DateTime.now().year - profile!.birthYear!;
    final flag = switch (profile?.country) {
      'KR' => '🇰🇷',
      'JP' => '🇯🇵',
      _ => '',
    };

    return Row(
      children: [
        Flexible(
          child: Text(
            [profile?.nickname ?? '', if (age != null) '$age'].join(' ').trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (flag.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(flag, style: const TextStyle(fontSize: 20)),
        ],
        const Spacer(),
        const _StatPill(
          icon: Icons.favorite,
          iconColor: Color(0xFFE85D6E),
          label: '—',
        ),
        const SizedBox(width: 8),
        const _StatPill(
          icon: Icons.chat_bubble_outline,
          iconColor: AppColors.textSecondary,
          label: '—',
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하루 한 마디 ─────────────────────────────────────────
class _OneLiner extends ConsumerWidget {
  const _OneLiner({required this.post});

  static const int maxLength = 25;

  final MyPost post;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: post.oneLiner ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          '하루 한 마디',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: maxLength,
          cursorColor: AppColors.moonlight,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '오늘의 기분을 한 줄로 남겨보세요',
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
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (text == null || !context.mounted) return;
    final error = await ref.read(myPostProvider.notifier).updateOneLiner(text);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = post.oneLiner;
    final length = text?.characters.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '하루 한 마디',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$length/$maxLength',
              style: const TextStyle(color: AppColors.gold, fontSize: 14),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _edit(context, ref),
              child: Text(
                text == null || text.isEmpty ? '작성' : '수정',
                style: const TextStyle(color: AppColors.moonlight),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gapSm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text == null || text.isEmpty ? '하루 한 마디를 입력해 주세요.' : text,
                  style: TextStyle(
                    color: text == null || text.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.nightlight_round,
                color: AppColors.moonlight,
                size: 22,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 공유 버튼 ────────────────────────────────────────────
class _ShareButton extends ConsumerWidget {
  const _ShareButton({required this.post});

  final MyPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = post.gateOpen;

    return SizedBox(
      width: double.infinity,
      height: AppDimens.buttonHeight,
      child: FilledButton.icon(
        onPressed: enabled
            ? () async {
                final error = await ref.read(myPostProvider.notifier).publish();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(error ?? '포스트를 공유했어요 🌙')),
                  );
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3A3E9E),
          disabledBackgroundColor: AppColors.surfaceHigh,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        ),
        icon: Icon(post.published ? Icons.check : Icons.ios_share, size: 20),
        label: Text(
          post.published ? '공유됨 · 다시 공유하기' : '포스트 공유하기',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
