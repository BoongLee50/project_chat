import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'packet.dart';

/// 실시간 채팅용 WebSocket 클라이언트. (docs/01 §2, docs/03 §2)
///
/// 연결 직후 `AUTH` 패킷으로 JWT를 검증받고, 수신 패킷을 [packets] 스트림으로 흘린다.
/// 밤새 켜두는 앱이라 끊기면 지수 백오프로 재연결하고, heartbeat(PING)로 접속 상태를 유지한다.
class SocketClient {
  SocketClient({required TokenStorage tokenStorage, Future<bool> Function()? refreshToken})
    // ignore: prefer_initializing_formals (named private param은 Dart에서 불가)
    // ignore: prefer_initializing_formals
    : _tokenStorage = tokenStorage,
      // ignore: prefer_initializing_formals
      _refreshToken = refreshToken;

  /// 핸드셰이크가 이 시간 안에 끝나지 않으면 실패로 보고 재연결한다.
  static const _handshakeTimeout = Duration(seconds: 10);

  final TokenStorage _tokenStorage;

  /// AUTH_FAIL 때 액세스 토큰을 갱신하는 콜백(DioClient 재사용).
  final Future<bool> Function()? _refreshToken;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeat;
  Timer? _reconnect;
  int _retry = 0;
  int _seq = 0;
  bool _disposed = false;
  bool _connecting = false;
  DateTime _lastPacketAt = DateTime.now();

  final _controller = StreamController<Packet>.broadcast();

  /// 서버가 보내는 모든 패킷.
  Stream<Packet> get packets => _controller.stream;

  bool get isConnected => _channel != null;

  /// 소켓 URL — REST base URL의 스킴만 ws/wss로 바꾼다.
  static String get _url {
    final base = AppConfig.apiBaseUrl;
    final wsBase = base.startsWith('https')
        ? base.replaceFirst('https', 'wss')
        : base.replaceFirst('http', 'ws');
    return '$wsBase/ws';
  }

  Future<void> connect() async {
    if (_disposed || _connecting || _channel != null) return;
    _connecting = true;

    WebSocketChannel? channel;
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) return;

      channel = WebSocketChannel.connect(Uri.parse(_url));
      // 핸드셰이크 완료를 반드시 기다린다. 기다리지 않으면 연결에 실패해도
      // _channel이 채워진 채로 남아 이후 send가 조용히 버려진다.
      // 타임아웃이 없으면 ready가 영영 완료되지 않는 경우 재연결도 못 걸린다.
      await channel.ready.timeout(_handshakeTimeout);
      if (_disposed) {
        await channel.sink.close();
        return;
      }

      final connected = channel;
      _channel = connected;
      if (kDebugMode) debugPrint('[socket] 연결됨: $_url');
      _subscription = connected.stream.listen(
        _onData,
        onDone: () {
          if (kDebugMode) debugPrint('[socket] 연결 종료됨');
          _onDisconnected(connected);
        },
        onError: (Object e) {
          if (kDebugMode) debugPrint('[socket] 스트림 오류: $e');
          _onDisconnected(connected);
        },
        cancelOnError: true,
      );
      // sink 쪽 에러(전송 중 끊김)는 스트림으로 오지 않을 수 있어 따로 잡는다.
      unawaited(connected.sink.done.catchError((Object _) {}));

      send(Op.auth, {'accessToken': token});
      _startHeartbeat();
    } catch (e) {
      if (kDebugMode) debugPrint('[socket] 연결 실패: $e');
      if (channel != null && !identical(channel, _channel)) {
        unawaited(channel.sink.close().catchError((Object _) {}));
      }
      _onDisconnected(null);
    } finally {
      _connecting = false;
    }
  }

  void _onData(dynamic raw) {
    _lastPacketAt = DateTime.now();
    if (raw is! String) return;
    try {
      final packet = Packet.decode(raw);
      if (packet.op == Op.authOk) {
        _retry = 0; // 인증까지 성공해야 재연결 백오프를 초기화
        if (kDebugMode) debugPrint('[socket] AUTH_OK');
      } else if (packet.op == Op.authFail) {
        // 액세스 토큰이 만료된 채로 붙은 경우 — 갱신하고 다시 붙는다.
        if (kDebugMode) debugPrint('[socket] AUTH_FAIL → 토큰 갱신 후 재연결');
        unawaited(_reauthenticate());
        return;
      }
      _controller.add(packet);
    } catch (_) {
      // 해석 불가 패킷은 무시
    }
  }

  /// AUTH 실패 → 토큰을 갱신하고 새 연결로 다시 인증한다(1회).
  Future<void> _reauthenticate() async {
    _teardown();
    if (_disposed) return;
    final refreshed = await _refreshToken?.call() ?? false;
    if (!refreshed || _disposed) return;
    await connect();
  }

  /// [stale]이 지금 쓰는 채널이 아니면(이미 재연결된 뒤 늦게 온 이벤트) 무시한다.
  void _onDisconnected(WebSocketChannel? stale) {
    if (stale != null && !identical(stale, _channel)) return;
    _teardown();
    if (_disposed) return;

    // 지수 백오프(최대 30초)로 재연결.
    final delay = Duration(seconds: (1 << _retry).clamp(1, 30));
    _retry = (_retry + 1).clamp(0, 5);
    _reconnect?.cancel();
    _reconnect = Timer(delay, connect);
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _lastPacketAt = DateTime.now();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      // PONG조차 오지 않으면 연결이 반쯤 죽은 상태(half-open) — 강제로 다시 붙는다.
      if (DateTime.now().difference(_lastPacketAt) > const Duration(seconds: 90)) {
        _onDisconnected(_channel);
        return;
      }
      send(Op.ping, const {});
    });
  }

  /// 패킷 전송. seq를 자동으로 채워 ACK 매칭에 쓸 수 있게 한다.
  int? send(String op, Map<String, dynamic> data) {
    final channel = _channel;
    if (channel == null) return null;
    final seq = ++_seq;
    try {
      channel.sink.add(Packet(op: op, seq: seq, data: data).encode());
      return seq;
    } catch (_) {
      _onDisconnected(channel);
      return null;
    }
  }

  void _teardown() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// 로그아웃 등으로 연결을 끊을 때(재연결하지 않음).
  void disconnect() {
    _reconnect?.cancel();
    _teardown();
  }

  void dispose() {
    _disposed = true;
    _reconnect?.cancel();
    _teardown();
    _controller.close();
  }
}
