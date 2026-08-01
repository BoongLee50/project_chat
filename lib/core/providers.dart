import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/datasources/auth_api.dart';
import '../features/chat/data/datasources/chat_api.dart';
import '../features/garden/data/datasources/garden_api.dart';
import '../features/post/data/datasources/post_api.dart';
import '../features/profile/data/datasources/profile_api.dart';
import 'network/dio_client.dart';
import 'network/packet.dart';
import 'network/socket_client.dart';
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

final postApiProvider = Provider<PostApi>(
  (ref) => PostApi(ref.watch(dioClientProvider)),
);

final gardenApiProvider = Provider<GardenApi>(
  (ref) => GardenApi(ref.watch(dioClientProvider)),
);

final chatApiProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.watch(dioClientProvider)),
);

/// 실시간 소켓. 로그인 후 연결하고 로그아웃 시 끊는다(session_provider).
final socketClientProvider = Provider<SocketClient>((ref) {
  final client = SocketClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    refreshToken: () => ref.read(dioClientProvider).refreshTokens(),
  );
  ref.onDispose(client.dispose);
  return client;
});

/// 소켓 수신 패킷 스트림 — 화면/프로바이더가 구독해 실시간 갱신에 사용.
final socketPacketProvider = StreamProvider<Packet>(
  (ref) => ref.watch(socketClientProvider).packets,
);

/// 인증이 걸린 이미지 URL(`GET /files?key=`)을 로드할 때 쓸 헤더.
/// `Image.network`는 dio 인터셉터를 타지 않으므로 헤더를 직접 넘겨야 한다.
final authHeadersProvider = FutureProvider<Map<String, String>>((ref) async {
  final token = await ref.watch(tokenStorageProvider).readAccessToken();
  return token == null ? const {} : {'Authorization': 'Bearer $token'};
});
