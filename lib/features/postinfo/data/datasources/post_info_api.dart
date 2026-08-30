import '../../../../core/network/dio_client.dart';
import '../models/post_info.dart';

/// [포스트 정보] 공통 화면. 부르는 곳이 셋이라 호출도 하나로 둔다.
class PostInfoApi {
  const PostInfoApi(this._client);

  final DioClient _client;

  Future<PostInfo> get(String targetUserId) async {
    final data = await _client.get('/users/$targetUserId/post-info');
    return PostInfo.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
