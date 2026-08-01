import '../../../../core/network/dio_client.dart';
import '../models/me_profile.dart';

/// 온보딩/프로필 REST 호출. (docs/01-protocol-api-spec.md §1.2)
class ProfileApi {
  const ProfileApi(this._client);

  final DioClient _client;

  /// 닉네임 사용 가능 여부(특수문자·길이·중복·금지어는 서버가 판정).
  Future<bool> isNicknameAvailable(String value) async {
    final data = await _client.get(
      '/profile/nickname:check',
      query: {'value': value},
    );
    return (data as Map)['available'] as bool? ?? false;
  }

  /// 프로필 생성(온보딩 완료).
  Future<void> createProfile({
    required String nickname,
    required int birthYear,
    required String gender,
    required String country,
  }) async {
    await _client.post(
      '/profile',
      body: {
        'nickname': nickname,
        'birthYear': birthYear,
        'gender': gender,
        'country': country,
      },
    );
  }

  /// 내 프로필 조회.
  Future<MeProfile> me() async {
    final data = await _client.get('/me');
    return MeProfile.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
