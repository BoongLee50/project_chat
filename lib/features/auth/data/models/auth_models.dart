// 인증 관련 DTO. (docs/01-protocol-api-spec.md §1.1)

/// 소셜 로그인 결과 상태.
enum AuthStatus {
  /// 신규 가입 — 프로필 작성 필요
  newUser,

  /// 기존 회원이나 프로필 미완성
  profileRequired,

  /// 정상(프로필 완료)
  active,

  /// 영구 정지
  banned;

  static AuthStatus fromJson(String value) => switch (value) {
    'NEW' => AuthStatus.newUser,
    'PROFILE_REQUIRED' => AuthStatus.profileRequired,
    'ACTIVE' => AuthStatus.active,
    'BANNED' => AuthStatus.banned,
    _ => AuthStatus.profileRequired,
  };

  /// 온보딩(프로필 생성)이 필요한 상태인가.
  bool get needsProfile =>
      this == AuthStatus.newUser || this == AuthStatus.profileRequired;
}

/// 소셜 인증 제공자.
enum SocialProvider {
  line('LINE'),
  kakao('KAKAO'),
  google('GOOGLE');

  const SocialProvider(this.wireName);

  /// 서버가 기대하는 문자열 값.
  final String wireName;
}

class AuthResult {
  const AuthResult({
    required this.status,
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.nickname,
  });

  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final String? nickname;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return AuthResult(
      status: AuthStatus.fromJson(json['status'] as String? ?? ''),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      userId: user is Map ? user['id'] as String? : null,
      nickname: user is Map ? user['nickname'] as String? : null,
    );
  }
}

/// 야간 게이트 상태. (`GET /system/gate`)
class GateState {
  const GateState({required this.open, this.nextOpenAt});

  final bool open;
  final DateTime? nextOpenAt;

  factory GateState.fromJson(Map<String, dynamic> json) => GateState(
    open: json['open'] as bool? ?? false,
    nextOpenAt: json['nextOpenAt'] == null
        ? null
        : DateTime.tryParse(json['nextOpenAt'] as String),
  );
}
