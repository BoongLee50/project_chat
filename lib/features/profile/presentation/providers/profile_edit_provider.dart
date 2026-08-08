import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../auth/presentation/providers/session_provider.dart';

/// 프로필 편집(사진·관심사·소개·지역) — 성공하면 null, 실패하면 보여줄 메시지.
///
/// 프로필 화면은 `sessionProvider`의 값을 그리므로, 저장 후 세션을 다시 읽어
/// 화면이 즉시 따라오게 한다.
class ProfileEditActions {
  const ProfileEditActions(this._ref);

  final Ref _ref;

  Future<ApiException?> updatePhoto(List<int> bytes) =>
      _run(() => _ref.read(profileApiProvider).uploadProfilePhoto(bytes: bytes));

  Future<ApiException?> deletePhoto() =>
      _run(() => _ref.read(profileApiProvider).deleteProfilePhoto());

  Future<ApiException?> updateInterests(List<String> codes) =>
      _run(() => _ref.read(profileApiProvider).updateInterests(codes));

  Future<ApiException?> updateIntro(String intro) =>
      _run(() => _ref.read(profileApiProvider).updateIntro(intro));

  Future<ApiException?> updateRegions(List<String> codes) =>
      _run(() => _ref.read(profileApiProvider).updateRegions(codes));

  Future<ApiException?> _run(Future<void> Function() action) async {
    try {
      await action();
      await _ref.read(sessionProvider.notifier).refresh();
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }
}

final profileEditActionsProvider =
    Provider<ProfileEditActions>(ProfileEditActions.new);
