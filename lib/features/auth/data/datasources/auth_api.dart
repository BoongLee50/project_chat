import '../../../../core/network/dio_client.dart';
import '../models/auth_models.dart';

/// 인증/게이트 REST 호출. (docs/01-protocol-api-spec.md §1.1)
class AuthApi {
  const AuthApi(this._client);

  final DioClient _client;

  /// 소셜 로그인 — providerToken은 소셜 SDK가 준 토큰.
  /// 개발 중에는 서버의 mock provider가 임의 문자열을 받아준다.
  Future<AuthResult> socialLogin({
    required SocialProvider provider,
    required String providerToken,
  }) async {
    final data = await _client.post(
      '/auth/social',
      noAuth: true,
      body: {'provider': provider.wireName, 'providerToken': providerToken},
    );
    return AuthResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// 야간 게이트 상태 조회(오픈 여부/다음 오픈 시각).
  Future<GateState> gate() async {
    final data = await _client.get('/system/gate', noAuth: true);
    return GateState.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
