import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/util/freshness.dart';
import '../../data/models/feed_item.dart';

/// 현재 적용된 피드 필터(성별/연령대/국가). 바뀌면 피드를 다시 읽는다.
class FeedFilterController extends Notifier<FeedFilter> {
  @override
  FeedFilter build() => const FeedFilter();

  // 드롭다운은 **고른 값을 그대로 적용**한다(토글이 아니다).
  // 셋 다 항상 하나가 선택된 상태이고, null이 "전체"라는 선택이다.
  //
  // 전에는 토글이라 같은 값을 다시 고르면 해제됐고, 이미 "전체"인데 "전체"를 다시
  // 고르면 gender=''·ageDecade=-1 같은 **없는 값**이 됐다. 목록에서 고르는 UI에
  // 토글은 맞지 않는다 — 고른 게 그대로 켜져야 한다.

  void selectGender(String? value) => state = value == null
      ? state.copyWith(clearGender: true)
      : state.copyWith(gender: value);

  void selectAge(int? decade) => state = decade == null
      ? state.copyWith(clearAge: true)
      : state.copyWith(ageDecade: decade);

  void selectCountry(String? value) => state = value == null
      ? state.copyWith(clearCountry: true)
      : state.copyWith(country: value);
}

final feedFilterProvider = NotifierProvider<FeedFilterController, FeedFilter>(
  FeedFilterController.new,
);

/// 피드 목록. 필터가 바뀌면 자동으로 다시 조회된다.
class FeedController extends AsyncNotifier<List<FeedItem>>
    implements RefreshableIfStale {
  String? _nextCursor;

  /// 피드는 서버가 알려줄 방법이 없어(소켓 이벤트가 없다) 시간으로 끊는다.
  /// 스킵했던 사람이 사진·프로필을 갱신하면 다시 뜨는데, 그걸 보려면 다시 읽어야 한다.
  final _freshness = Freshness();

  @override
  Future<List<FeedItem>> build() async {
    final filter = ref.watch(feedFilterProvider);

    final page = await ref
        .read(gardenApiProvider)
        .feed(
          gender: filter.gender,
          ageDecade: filter.ageDecade,
          country: filter.country,
        );
    _nextCursor = page.nextCursor;
    _freshness.markLoaded();
    return page.items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// 탭에 다시 들어오거나 앱이 복귀했을 때 호출된다.
  /// 방금 읽었으면 아무것도 하지 않는다 — 탭을 오갈 때마다 요청이 나가지 않도록.
  @override
  Future<void> refreshIfStale() async {
    if (!_freshness.isStale) return;
    // 조용히 바꾼다 — 로딩 스피너를 띄우면 보고 있던 카드가 사라져 깜빡인다.
    final next = await AsyncValue.guard(() => build());
    if (next.hasValue) state = next;
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
          );
      _nextCursor = page.nextCursor;
      state = AsyncValue.data([...current, ...page.items]);
    } on ApiException {
      // 추가 로드 실패는 조용히 무시(기존 목록 유지)
    }
  }

  /// 좋아요. **하루 한 번**이라 이미 누른 카드에는 아무것도 하지 않는다(서버도 같은 판정).
  /// 성공하면 해당 카드의 카운트를 낙관적으로 올린다.
  Future<ApiException?> like(FeedItem item) async {
    if (item.likedByMe) return null;
    try {
      await ref.read(gardenApiProvider).like(item.userId);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncValue.data([
          for (final e in current)
            if (e.userId == item.userId)
              e.copyWith(likes: e.likes + 1, likedByMe: true)
            else
              e,
        ]);
      }
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }

  /// 댓글(답글 포함)을 하나 달았다 — 그 카드의 댓글 수를 올린다.
  ///
  /// 서버도 댓글·답글마다 `post_stats.comments`를 1 올리므로(`GardenService.addComment`)
  /// 다시 읽지 않고 같은 셈을 여기서 한다. 전에는 이게 없어서 **창을 닫아도 숫자가 그대로**였다.
  void commentAdded(String userId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final e in current)
        if (e.userId == userId) e.copyWith(comments: e.comments + 1) else e,
    ]);
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
}

final feedProvider = AsyncNotifierProvider<FeedController, List<FeedItem>>(
  FeedController.new,
);

/// 댓글 목록. 키는 `"<대상종류>:<대상id>"` —
/// 포스트와 달빛 한마디가 **같은 화면**을 쓰므로 id만으로는 구분되지 않는다.
///
/// ⚠️ **autoDispose다** — 시트를 닫으면 버리고 열 때마다 새로 읽는다. 전에는 첫 목록이 캐시에 남아
/// **다시 열어도 그 사이 남이 단 댓글이 안 보였다**(2026-10-04 실기 확인).
final commentsProvider = FutureProvider.autoDispose
    .family<List<Comment>, String>((ref, key) {
      final i = key.indexOf(':');
      final kind = key.substring(0, i);
      final id = key.substring(i + 1);
      return kind == 'dailyAnswer'
          ? ref.read(dailyApiProvider).comments(id)
          : ref.read(gardenApiProvider).comments(id);
    });
