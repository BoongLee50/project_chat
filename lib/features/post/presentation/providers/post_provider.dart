import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../data/models/my_post.dart';

/// 오늘의 포스트 상태(홈 화면).
///
/// 조회는 [AsyncNotifier]가, 등록/삭제/공유 같은 동작은 메서드가 담당하고
/// 성공하면 서버 상태를 다시 읽어 화면을 갱신한다.
class MyPostController extends AsyncNotifier<MyPost> {
  @override
  Future<MyPost> build() => ref.read(postApiProvider).myPost();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(postApiProvider).myPost());
  }

  /// 촬영/선택한 사진을 업로드하고 목록을 갱신한다.
  /// 실패 시 사용자에게 보여줄 메시지를 반환(성공이면 null).
  Future<ApiException?> addPhoto(List<int> bytes) =>
      _run(() => ref.read(postApiProvider).uploadPhoto(bytes: bytes));

  Future<ApiException?> deletePhoto(String photoId) =>
      _run(() => ref.read(postApiProvider).deletePhoto(photoId));

  /// 대표 사진 지정. 승계 규칙(등록/삭제 시 자동 지정)은 서버가 처리하므로
  /// 여기서는 사용자가 직접 고른 경우만 다룬다.
  Future<ApiException?> setMainPhoto(String photoId) =>
      _run(() => ref.read(postApiProvider).setMainPhoto(photoId));


  Future<ApiException?> publish() => _run(() => ref.read(postApiProvider).publish());

  /// 공통 실행기: 동작 수행 → 성공 시 재조회, 실패 시 메시지 반환.
  /// (실패해도 기존 화면 데이터는 유지 — 에러로 화면을 비우지 않는다)
  Future<ApiException?> _run(Future<void> Function() action) async {
    try {
      await action();
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }
}

final myPostProvider = AsyncNotifierProvider<MyPostController, MyPost>(
  MyPostController.new,
);
