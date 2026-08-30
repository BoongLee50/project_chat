import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/main_shell.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../data/models/feed_item.dart';

/// 상대의 포스트 사진을 넘겨 보는 창(기획 4-1).
///
/// **달빛가든에서 좌우 스와이프는 "사람"을 넘긴다.** 사진을 넘기는 건 이 창 안에서다 —
/// 카드를 **눌렀다 떼면** 열린다. 두 스와이프가 한 화면에 겹치면 어느 쪽인지 알 수 없어진다.
///
/// 볼 수 있는 장수는 상대가 무료면 2장, 앨범패스면 9장이고,
/// **보는 쪽**이 오늘 자기 포스트를 공유하지 않은 무료 사용자면 **메인 1장만** 온다
/// (③단계 열람 제한 — 서버가 잘라 보낸다). 그때 마지막에 [사진 등록 안내창]이 한 장 더 붙는다.
///
/// 📌 ⑥단계의 [포스트 정보] 공통 화면이 이 창을 품게 될 가능성이 높다 —
/// 그때 `shared/`로 옮기면 된다.
Future<void> showPostPhotoViewer(BuildContext context, FeedItem item) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => _PostPhotoViewer(item: item),
  );
}

class _PostPhotoViewer extends ConsumerStatefulWidget {
  const _PostPhotoViewer({required this.item});

  final FeedItem item;

  @override
  ConsumerState<_PostPhotoViewer> createState() => _PostPhotoViewerState();
}

class _PostPhotoViewerState extends ConsumerState<_PostPhotoViewer> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 잠금 안내가 붙는지 — 볼 수 있는 것보다 실제 장수가 많을 때만.
  bool get _hasLockPage => widget.item.photoLocked;

  int get _pageCount => widget.item.photoUrls.length + (_hasLockPage ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final photos = widget.item.photoUrls;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                widget.item.nickname,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              // 시안(4-1)은 눈금이 아니라 **숫자 표기**다.
              Text(
                '${_page + 1}/${widget.item.totalPhotos}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: l10n.commonClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              child: AspectRatio(
                aspectRatio: 0.86,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pageCount,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => i < photos.length
                      ? AuthedImage(url: photos[i])
                      : const _LockPage(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 잠긴 사진 자리에 대신 놓이는 안내(기획 4-1 [사진 등록 안내창]).
///
/// 잠긴 사진을 흐릿하게라도 보여주지 않는다 — **서버가 URL을 아예 주지 않기** 때문이고,
/// 그게 열람 제한이 실제로 걸려 있다는 뜻이다.
class _LockPage extends ConsumerWidget {
  const _LockPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.pagePad),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.moonlight,
              size: 40,
            ),
            const SizedBox(height: AppDimens.gapMd),
            Text(
              l10n.gardenPhotoLockedBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimens.gapLg),
            FilledButton(
              onPressed: () {
                // 열쇠는 상품이 아니라 **내 포스트**다 — 상점이 아니라 포스트 탭으로 보낸다.
                Navigator.pop(context);
                ref.read(selectedTabProvider.notifier).state = MainTab.post;
              },
              child: Text(l10n.gardenPhotoLockedAction),
            ),
          ],
        ),
      ),
    );
  }
}
