import '../../../../core/network/dio_client.dart';

/// 신고·차단 REST 호출. (docs/01 §1.7)
class ModerationApi {
  const ModerationApi(this._client);

  final DioClient _client;

  /// 신고. [reason]은 사유 코드, [detail]은 "기타"일 때의 자유 서술.
  Future<void> report({
    required String targetUserId,
    required String reason,
    String? detail,
  }) => _client.post(
    '/reports',
    body: {
      'targetUserId': targetUserId,
      'reason': reason,
      if (detail != null && detail.isNotEmpty) 'detail': detail,
    },
  );

  Future<void> block(String targetUserId) =>
      _client.post('/blocks', body: {'targetUserId': targetUserId});
}
