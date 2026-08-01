import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../error/api_exception.dart';
import '../storage/token_storage.dart';

/// REST 클라이언트. 요청에 JWT를 붙이고, 401이면 refresh 후 1회 재시도한다.
/// (docs/03-flutter-structure.md §2 네트워킹 레이어)
class DioClient {
  DioClient({required TokenStorage tokenStorage, Dio? dio})
    // ignore: prefer_initializing_formals (named private param은 Dart에서 불가)
    : _tokenStorage = tokenStorage,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
              contentType: 'application/json',
              // 4xx도 예외로 던지지 않고 아래 인터셉터/변환에서 일관 처리.
              validateStatus: (status) => status != null && status < 500,
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['noAuth'] != true) {
            final token = await _tokenStorage.readAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          // 401이면 refreshToken으로 갱신 후 원 요청을 1회 재시도.
          final isRetry = response.requestOptions.extra['retried'] == true;
          if (response.statusCode == 401 && !isRetry) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              try {
                final retried = await _retry(response.requestOptions);
                return handler.resolve(retried);
              } on DioException catch (e) {
                return handler.next(e.response ?? response);
              }
            }
          }
          handler.next(response);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio get raw => _dio;

  /// 액세스 토큰을 강제로 갱신한다(소켓 AUTH 실패 복구 등 REST 밖에서도 필요).
  Future<bool> refreshTokens() => _tryRefresh();

  Future<bool> _tryRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = res.data;
      if (res.statusCode == 200 && data is Map) {
        await _tokenStorage.save(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        return true;
      }
    } on DioException {
      // 갱신 실패 → 아래에서 false 반환(호출부가 로그아웃 처리)
    }
    await _tokenStorage.clear();
    return false;
  }

  Future<Response<dynamic>> _retry(RequestOptions options) {
    return _dio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: options.headers,
        extra: {...options.extra, 'retried': true},
      ),
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool noAuth = false,
  }) async {
    return _send(
      () =>
          _dio.get(path, queryParameters: query, options: _options(noAuth)),
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool noAuth = false,
  }) async {
    return _send(
      () => _dio.post(
        path,
        data: body,
        queryParameters: query,
        options: _options(noAuth),
      ),
    );
  }

  Future<dynamic> put(String path, {Object? body, bool noAuth = false}) async {
    return _send(() => _dio.put(path, data: body, options: _options(noAuth)));
  }

  Future<dynamic> delete(String path, {bool noAuth = false}) async {
    return _send(() => _dio.delete(path, options: _options(noAuth)));
  }

  /// 파일 바이트를 그대로 PUT 한다(스토리지 업로드 URL 전용).
  ///
  /// 로컬 스토리지 모드의 업로드 URL(`/internal/files?key=...`)은 우리 서버라
  /// 인증 헤더가 필요하고, S3 presigned URL은 절대 URL이라 baseUrl이 무시된다.
  Future<void> putBytes(
    String url, {
    required List<int> bytes,
    required String contentType,
  }) async {
    await _send(
      () => _dio.put(
        url,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            Headers.contentTypeHeader: contentType,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      ),
    );
  }

  Options _options(bool noAuth) => Options(extra: {'noAuth': noAuth});

  /// 응답 상태를 확인해 성공이면 body를, 실패면 [ApiException]을 던진다.
  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    final Response<dynamic> response;
    try {
      response = await request();
    } on DioException catch (e) {
      throw ApiException(
        message: _networkMessage(e),
        statusCode: e.response?.statusCode,
      );
    }

    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return response.data;

    final data = response.data;
    throw ApiException(
      message: data is Map && data['message'] is String
          ? data['message'] as String
          : '요청을 처리하지 못했어요. (오류 $status)',
      code: data is Map ? data['code'] as String? : null,
      statusCode: status,
    );
  }

  String _networkMessage(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => '서버 응답이 늦어요. 잠시 후 다시 시도해 주세요.',
      DioExceptionType.connectionError =>
        '서버에 연결할 수 없어요. 네트워크를 확인해 주세요.',
      _ => '통신 중 문제가 발생했어요.',
    };
  }
}
