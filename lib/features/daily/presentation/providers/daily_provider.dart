import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../data/models/daily_models.dart';

/// 오늘의 질문(타이틀 화면). 18시에 바뀌므로 **화면에 들어올 때마다 다시 읽는다** —
/// 그래서 `autoDispose`다. 남겨 두면 18시가 지난 뒤에도 "이미 답했다"는 옛 값으로 타이틀을 건너뛰고
/// 목록을 열어 서버가 403을 준다(2026-10-11: 답했으면 타이틀을 건너뛰게 되면서 생긴 조건).
final dailyTodayProvider = FutureProvider.autoDispose<DailyToday>(
  (ref) => ref.read(dailyApiProvider).today(),
);

/// 목록 정렬. 바뀌면 목록이 자동으로 다시 읽힌다. 다시 들어오면 기본 [최신]으로(기획 9-2).
final dailySortProvider = StateProvider.autoDispose<DailySort>(
  (ref) => DailySort.latest,
);

/// [답글 목록]. 들어올 때마다 새로 읽는다(`autoDispose` — 위 [dailyTodayProvider]와 같은 이유).
class DailyListController extends AutoDisposeAsyncNotifier<List<DailyAnswer>> {
  @override
  Future<List<DailyAnswer>> build() {
    final sort = ref.watch(dailySortProvider);
    return ref.read(dailyApiProvider).answers(sort: sort);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => build());
  }

  /// 좋아요. 사람마다 한 번이라 **이미 누른 뒤에는 아무것도 하지 않는다**.
  Future<ApiException?> like(DailyAnswer answer) async {
    if (answer.likedByMe) return null;
    try {
      await ref.read(dailyApiProvider).like(answer.id);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }
}

final dailyListProvider =
    AsyncNotifierProvider.autoDispose<DailyListController, List<DailyAnswer>>(
      DailyListController.new,
    );

/// 상세 한 건.
final dailyAnswerProvider = FutureProvider.family<DailyAnswer, String>(
  (ref, answerId) => ref.read(dailyApiProvider).answer(answerId),
);
