import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../data/models/daily_models.dart';
import '../providers/daily_provider.dart';
import 'daily_detail_screen.dart';
import 'daily_write_screen.dart';

/// 달빛 한마디 [목록](기획 8-1). 최신순/인기순 + [내 한마디] + 작성 버튼.
class DailyListScreen extends ConsumerWidget {
  const DailyListScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const DailyListScreen());

  /// [내 한마디] — 아직 안 썼으면 서버가 `DAILY_ANSWER_NOT_YET`을 준다.
  /// 오류가 아니라 **안내**라서 문구만 띄우고 화면은 그대로 둔다(기획 8-1).
  Future<void> _openMine(BuildContext context, WidgetRef ref) async {
    try {
      final mine = await ref.read(dailyApiProvider).myAnswer();
      if (!context.mounted) return;
      await Navigator.of(context).push(DailyDetailScreen.route(mine.id));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(L10n.of(context), e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final today = ref.watch(dailyTodayProvider).valueOrNull;
    final sort = ref.watch(dailySortProvider);
    final list = ref.watch(dailyListProvider);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.dailyTitle),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () async {
          await Navigator.of(context).push(DailyWriteScreen.route());
          ref.invalidate(dailyTodayProvider);
          ref.read(dailyListProvider.notifier).refresh();
        },
        child: const Icon(Icons.edit_rounded, color: AppColors.night),
      ),
      body: Column(
        children: [
          if (today != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.pagePad,
                0,
                AppDimens.pagePad,
                AppDimens.gapMd,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.gapMd),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(color: AppColors.moonlight),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.dailyTodayQuestion,
                      style: const TextStyle(
                        color: AppColors.moonlight,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      today.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePad),
            child: Row(
              children: [
                _SortChip(
                  label: l10n.dailySortLatest,
                  selected: sort == DailySort.latest,
                  onTap: () => ref.read(dailySortProvider.notifier).state =
                      DailySort.latest,
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: l10n.dailySortPopular,
                  selected: sort == DailySort.popular,
                  onTap: () => ref.read(dailySortProvider.notifier).state =
                      DailySort.popular,
                ),
                const Spacer(),
                _SortChip(
                  label: l10n.dailyMine,
                  selected: false,
                  onTap: () => _openMine(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.gapMd),
          Expanded(
            child: list.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.moonlight),
              ),
              error: (error, _) => Center(
                child: Text(
                  l10n.dailyLoadFailed,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Text(
                        l10n.dailyEmpty,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.moonlight,
                      backgroundColor: AppColors.surface,
                      onRefresh: () =>
                          ref.read(dailyListProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.pagePad,
                          0,
                          AppDimens.pagePad,
                          80,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppDimens.gapMd),
                        itemBuilder: (context, i) =>
                            _AnswerTile(answer: items[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.moonlight : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.moonlight : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.night : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 목록 한 줄. 누르면 상세로 간다(기획 8-1: "개별 목록 영역 선택 시 상세 호출").
class _AnswerTile extends ConsumerWidget {
  const _AnswerTile({required this.answer});

  final DailyAnswer answer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () =>
          Navigator.of(context).push(DailyDetailScreen.route(answer.id)),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.gapMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(
            // 내 글은 테두리로 구분해 둔다 — [내 한마디]로도 오지만 목록에서도 알아보게.
            color: answer.mine ? AppColors.moonlight : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          [
                            answer.nickname,
                            if (answer.age != null) '${answer.age}',
                          ].join(' '),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (answer.flag.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          answer.flag,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    answer.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        answer.likedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 15,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${answer.likes}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.mode_comment_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${answer.comments}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (answer.imageUrl != null) ...[
              const SizedBox(width: AppDimens.gapMd),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: AuthedImage(url: answer.imageUrl!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
