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

  /// 프로필 사진 교체: 업로드 URL 발급 → 바이트 직접 전송 → 등록.
  ///
  /// 포스트 사진(`PostApi.uploadPhoto`)과 **같은 3단 흐름**이다(docs/01 §1.2).
  /// 다만 프로필 사진은 여러 장이 아니라 **1장을 갈아끼우는 것**이라 등록이 PUT이고,
  /// 서버가 등록 시점에 이전 사진을 스토리지에서 지운다.
  Future<void> uploadProfilePhoto({
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final issued = await _client.post(
      '/me/profile-photo:upload-url',
      query: {'contentType': contentType},
    );
    final map = Map<String, dynamic>.from(issued as Map);

    await _client.putBytes(
      map['uploadUrl'] as String,
      bytes: bytes,
      contentType: contentType,
    );

    await _client.put(
      '/me/profile-photo',
      body: {'storageKey': map['storageKey']},
    );
  }

  /// 프로필 사진 제거.
  ///
  /// 등록과 **같은 엔드포인트**에 `storageKey: null`을 보낸다(docs/01 §1.2).
  /// 서버가 photo_key를 비우고 이전 파일을 스토리지에서 지운다.
  Future<void> deleteProfilePhoto() =>
      _client.put('/me/profile-photo', body: {'storageKey': null});

  /// 관심사 교체(최대 8). 서버가 전체를 덮어쓰므로 **선택된 전체 목록**을 보낸다.
  Future<void> updateInterests(List<String> codes) =>
      _client.put('/me/interests', body: {'codes': codes});

  /// 소개 한마디(최대 50자). 빈 문자열을 보내면 지워진다.
  Future<void> updateIntro(String intro) =>
      _client.put('/me/intro', body: {'intro': intro});

  /// 활동 지역 교체(최대 2). 관심사와 같은 전체 교체 방식.
  Future<void> updateRegions(List<String> codes) =>
      _client.put('/me/regions', body: {'codes': codes});
}
