import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../data/models/feed_item.dart';

/// 현재 적용된 피드 필터(성별/연령대/국가). 바뀌면 피드를 다시 읽는다.
class FeedFilterController extends Notifier<FeedFilter> {
  @override
  FeedFilter build() => const FeedFilter();

  void toggleGender(String value) => state = state.gender == value
      ? state.copyWith(clearGender: true)
      : state.copyWith(gender: value);

  void toggleAge(int decade) => state = state.ageDecade == decade
      ? state.copyWith(clearAge: true)
      : state.copyWith(ageDecade: decade);

  void toggleCountry(String value) => state = state.country == value
      ? state.copyWith(clearCountry: true)
      : state.copyWith(country: value);
}

final feedFilterProvider = NotifierProvider<FeedFilterController, FeedFilter>(
  FeedFilterController.new,
);

/// 스포트라이트 모드(부스팅 사용자만) 여부.
final spotlightProvider = StateProvider<bool>((ref) => false);

/// 피드 목록. 필터/스포트라이트가 바뀌면 자동으로 다시 조회된다.
class FeedController extends AsyncNotifier<List<FeedItem>> {
  String? _nextCursor;

  @override
  Future<List<FeedItem>> build() async {
    final filter = ref.watch(feedFilterProvider);
    final spotlight = ref.watch(spotlightProvider);

    final page = await ref
        .read(gardenApiProvider)
        .feed(
          gender: filter.gender,
          ageDecade: filter.ageDecade,
          country: filter.country,
          spotlight: spotlight,
        );
    _nextCursor = page.nextCursor;
    return page.items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// 다음 페이지를 이어붙인다(끝이면 아무것도 하지 않음).
  Future<void> loadMore() async {
    final cursor = _nextCursor;
    final current = state.valueOrNull;
    if (cursor == null || current == null) return;

    final filter = ref.read(feedFilterProvider);
    try {
      final page = await ref
          .read(gardenApiProvider)
          .feed(
            gender: filter.gender,
            ageDecade: filter.ageDecade,
            country: filter.country,
            cursor: cursor,
            spotlight: ref.read(spotlightProvider),
          );
      _nextCursor = page.nextCursor;
      state = AsyncValue.data([...current, ...page.items]);
    } on ApiException {
      // 추가 로드 실패는 조용히 무시(기존 목록 유지)
    }
  }

  /// 좋아요. 성공하면 해당 카드의 카운트를 낙관적으로 올린다.
  Future<ApiException?> like(FeedItem item) async {
    try {
      await ref.read(gardenApiProvider).like(item.userId);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncValue.data([
          for (final e in current)
            if (e.userId == item.userId) _withLikes(e, e.likes + 1) else e,
        ]);
      }
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  /// 스킵 — 목록에서 즉시 제거하고 서버에도 기록한다.
  Future<ApiException?> skip(FeedItem item) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        current.where((e) => e.userId != item.userId).toList(),
      );
    }
    try {
      await ref.read(gardenApiProvider).skip(item.userId);
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  static FeedItem _withLikes(FeedItem item, int likes) => FeedItem(
    userId: item.userId,
    nickname: item.nickname,
    age: item.age,
    country: item.country,
    pick: item.pick,
    online: item.online,
    oneLiner: item.oneLiner,
    photoUrls: item.photoUrls,
    interests: item.interests,
    likes: likes,
    comments: item.comments,
    score: item.score,
  );
}

final feedProvider = AsyncNotifierProvider<FeedController, List<FeedItem>>(
  FeedController.new,
);

/// 특정 사용자의 오늘 포스트 댓글 목록.
final commentsProvider = FutureProvider.family<List<Comment>, String>(
  (ref, targetUserId) => ref.read(gardenApiProvider).comments(targetUserId),
);
