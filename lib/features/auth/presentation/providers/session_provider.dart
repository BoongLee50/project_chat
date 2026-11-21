import 'dart:async';

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

  /// 이미 로그인한 사람이 앱을 켜면 타이틀 화면 [자동 로그인](버튼 없이 앱 이름만 가운데)을
  /// **최소 이만큼** 보여 준 뒤 들어간다(사용자 2026-11-21 — "1~2초 보여 주다가 바로 포스트로").
  /// 서버가 늦으면 그만큼 더 머문다. 처음 쓰는 사람(토큰 없음)은 기다리지 않고 바로 로그인 버튼이다.
  static const autoLoginHold = Duration(milliseconds: 1500);

  /// 앱 시작 시: 저장된 토큰이 있으면 /me로 프로필을 확인해 단계를 결정한다.
  Future<void> restore() async {
    final token = await ref.read(tokenStorageProvider).readAccessToken();
    if (token == null) {
      state = const SessionState(status: SessionStatus.unauthenticated);
      return;
    }
    // 프로필 확인은 바로 시작하고, 결과를 반영(= 화면 전환)하기 전에 최소 표시 시간을 채운다.
    // 반영되면 라우터가 메인(첫 탭 = 포스트)으로 보낸다.
    await _loadProfile(holdUntil: Future<void>.delayed(autoLoginHold));
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
    ref.read(socketClientProvider).disconnect();
    await ref.read(tokenStorageProvider).clear();
    state = const SessionState(status: SessionStatus.unauthenticated);
  }

  /// [holdUntil]이 있으면 결과를 상태에 반영하기 **전에** 그것을 기다린다(앱 시작의 최소 타이틀 시간).
  Future<void> _loadProfile({Future<void>? holdUntil}) async {
    try {
      final profile = await ref.read(profileApiProvider).me();
      await holdUntil;
      final authenticated = profile.isComplete;
      state = SessionState(
        status: authenticated
            ? SessionStatus.authenticated
            : SessionStatus.onboarding,
        profile: profile,
      );
      // 로그인이 확정되면 실시간 소켓을 연결한다(재연결은 SocketClient가 처리).
      if (authenticated) {
        unawaited(ref.read(socketClientProvider).connect());
      }
    } on ApiException catch (e) {
      await holdUntil;
      if (e.isUnauthorized) {
        await ref.read(tokenStorageProvider).clear();
        state = const SessionState(status: SessionStatus.unauthenticated);
      } else if (state.status == SessionStatus.loading) {
        // 앱 시작 복구 중 네트워크 실패 — 여기서 loading을 유지하면
        // 스플래시 화면에 갇히므로 로그인 화면으로 보내고 사유를 알린다.
        state = SessionState(
          status: SessionStatus.unauthenticated,
          error: e.message,
        );
      } else {
        state = state.copyWith(busy: false, error: e.message);
      }
    }
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
