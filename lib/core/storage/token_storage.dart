import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT 토큰 보관소. 기기 보안 저장소(Keystore/Keychain)를 사용한다.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';

  final FlutterSecureStorage _storage;

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccess, value: accessToken);
    await _storage.write(key: _keyRefresh, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _keyAccess);

  Future<String?> readRefreshToken() => _storage.read(key: _keyRefresh);

  Future<void> clear() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
  }
}
