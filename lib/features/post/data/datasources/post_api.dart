import '../../../../core/network/dio_client.dart';
import '../models/my_post.dart';

/// 오늘의 포스트 REST 호출. (docs/01-protocol-api-spec.md §1.3)
class PostApi {
  const PostApi(this._client);

  final DioClient _client;

  /// 오늘의 포스트 상태(사진·한마디·남은 시간·제한). 첫 호출 시 등록 창이 시작된다.
  Future<MyPost> myPost() async {
    final data = await _client.get('/posts/me');
    return MyPost.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// 사진 업로드: 업로드 URL 발급 → 바이트 직접 전송 → 메타 등록.
  Future<void> uploadPhoto({
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final issued = await _client.post(
      '/posts/photos:upload-url',
      query: {'contentType': contentType},
    );
    final map = Map<String, dynamic>.from(issued as Map);

    await _client.putBytes(
      map['uploadUrl'] as String,
      bytes: bytes,
      contentType: contentType,
    );

    await _client.post(
      '/posts/photos',
      body: {'storageKey': map['storageKey']},
    );
  }

  Future<void> deletePhoto(String photoId) =>
      _client.delete('/posts/photos/$photoId');


  /// 포스트 공유하기(사진 + 하루 한마디 필요).
  Future<void> publish() => _client.post('/posts:publish');
}
