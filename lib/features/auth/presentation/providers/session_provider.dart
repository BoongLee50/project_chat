import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../profile/data/models/me_profile.dart';
import '../../data/models/auth_models.dart';

/// 앱의 로그인/온보딩 진행 단계.
enum SessionStatus {
  /// 저장된 토큰 확인 중(스플래시)
  loading,

  /// 로그인 필요
  unauthenticated,

  /// 로그인은 됐으나 프로필(온보딩) 미완성
  onboarding,

  /// 로그인 + 프로필 완료
  authenticated,
}

class SessionState {
  const SessionState({
    required this.status,
    this.profile,
    this.busy = false,
    this.error,
  });

  final SessionStatus status;
  final MeProfile? profile;

  /// 로그인/프로필 생성 등 처리 중 여부(버튼 로딩 표시용).
  final bool busy;

  /// 마지막 실패 메시지(스낵바 표시용).
  final String? error;

  SessionState copyWith({
    SessionStatus? status,
    MeProfile? profile,
    bool? busy,
    String? error,
  }) => SessionState(
    status: status ?? this.status,
    profile: profile ?? this.profile,
    busy: busy ?? this.busy,
    error: error,
  );
}

/// 로그인 상태와 프로필을 보유하고, 라우터의 리다이렉트 기준이 되는 컨트롤러.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    Future.microtask(restore);
    return const SessionState(status: SessionStatus.loading);
  }

  /// 앱 시작 시: 저장된 토큰이 있으면 /me로 프로필을 확인해 단계를 결정한다.
  Future<void> restore() async {
    final token = await ref.read(tokenStorageProvider).readAccessToken();
    if (token == null) {
      state = const SessionState(status: SessionStatus.unauthenticated);
      return;
    }
    await _loadProfile();
  }

  /// 소셜 로그인. [providerToken]은 소셜 SDK 토큰(개발 중에는 목 문자열).
  Future<void> signIn({
    required SocialProvider provider,
    required String providerToken,
  }) async {
    state = state.copyWith(busy: true);
    try {
      final result = await ref
          .read(authApiProvider)
          .socialLogin(provider: provider, providerToken: providerToken);

      if (result.status == AuthStatus.banned) {
        state = const SessionState(
          status: SessionStatus.unauthenticated,
          error: '이용이 제한된 계정입니다.',
        );
        return;
      }

      await ref
          .read(tokenStorageProvider)
          .save(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken!,
          );

      if (result.status.needsProfile) {
        state = const SessionState(status: SessionStatus.onboarding);
      } else {
        await _loadProfile();
      }
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
    }
  }

  /// 온보딩 완료 후 프로필을 다시 읽어 authenticated로 전환.
  Future<void> completeOnboarding() => _loadProfile();

  /// 프로필 최신화(당겨서 새로고침 등).
  Future<void> refresh() => _loadProfile();

  Future<void> signOut() async {
    await ref.read(tokenStorageProvider).clear();
    state = const SessionState(status: SessionStatus.unauthenticated);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ref.read(profileApiProvider).me();
      state = SessionState(
        status: profile.isComplete
            ? SessionStatus.authenticated
            : SessionStatus.onboarding,
        profile: profile,
      );
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await ref.read(tokenStorageProvider).clear();
        state = const SessionState(status: SessionStatus.unauthenticated);
      } else {
        state = state.copyWith(busy: false, error: e.message);
      }
    }
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
