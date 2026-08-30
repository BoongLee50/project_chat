import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../data/models/daily_models.dart';

/// 오늘의 질문(타이틀 화면). 18시에 바뀌므로 화면에 들어올 때마다 다시 읽는다.
final dailyTodayProvider = FutureProvider<DailyToday>(
  (ref) => ref.read(dailyApiProvider).today(),
);

/// 목록 정렬. 바뀌면 목록이 자동으로 다시 읽힌다.
final dailySortProvider = StateProvider<DailySort>((ref) => DailySort.latest);

/// 달빛 한마디 목록.
class DailyListController extends AsyncNotifier<List<DailyAnswer>> {
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
    AsyncNotifierProvider<DailyListController, List<DailyAnswer>>(
      DailyListController.new,
    );

/// 상세 한 건.
final dailyAnswerProvider = FutureProvider.family<DailyAnswer, String>(
  (ref, answerId) => ref.read(dailyApiProvider).answer(answerId),
);
