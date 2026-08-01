import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/datasources/auth_api.dart';
import '../features/profile/data/datasources/profile_api.dart';
import 'network/dio_client.dart';
import 'storage/token_storage.dart';

/// 앱 전역 인프라 프로바이더(저장소·네트워크·API).

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(tokenStorage: ref.watch(tokenStorageProvider)),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioClientProvider)),
);

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.watch(dioClientProvider)),
);
