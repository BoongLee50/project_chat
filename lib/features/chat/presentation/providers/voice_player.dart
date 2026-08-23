import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/providers.dart';

/// 음성 메시지 재생.
///
/// 대화방 안에서 **한 번에 하나만** 재생한다. 말풍선마다 플레이어를 두면
/// 여러 개가 동시에 울리고, 각자 스트림을 물고 있어 정리도 어렵다.
/// 그래서 컨트롤러 하나가 "지금 재생 중인 messageId"를 들고 있는 모양으로 만들었다.
class VoicePlaybackState {
  const VoicePlaybackState({
    this.messageId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.loading = false,
  });

  /// 지금 재생(또는 로딩) 중인 메시지. 없으면 null.
  final String? messageId;
  final Duration position;
  final Duration duration;
  final bool playing;

  /// 파일을 내려받는 중. 첫 재생 때만 잠깐 true다.
  final bool loading;

  bool isActive(String id) => messageId == id;

  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }
}

class VoicePlayerController extends Notifier<VoicePlaybackState> {
  final _player = AudioPlayer();
  final _subs = <StreamSubscription<dynamic>>[];

  /// 내려받은 파일 캐시. 같은 메시지를 다시 들을 때 또 받지 않는다.
  final _cache = <String, String>{};

  @override
  VoicePlaybackState build() {
    _subs.add(
      _player.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed) {
          // 끝까지 들었으면 처음으로 되감아 둔다 — 다시 누르면 바로 재생된다.
          _player.pause();
          _player.seek(Duration.zero);
          state = VoicePlaybackState(
            messageId: state.messageId,
            duration: state.duration,
          );
          return;
        }
        state = VoicePlaybackState(
          messageId: state.messageId,
          position: state.position,
          duration: state.duration,
          playing: s.playing,
          loading: state.loading,
        );
      }),
    );
    _subs.add(
      _player.positionStream.listen((p) {
        if (state.messageId == null) return;
        state = VoicePlaybackState(
          messageId: state.messageId,
          position: p,
          duration: state.duration,
          playing: state.playing,
          loading: state.loading,
        );
      }),
    );

    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _player.dispose();
    });
    return const VoicePlaybackState();
  }

  /// 재생/일시정지 토글.
  ///
  /// [messageId]는 캐시 키이자 "누가 재생 중인가"의 식별자다.
  /// [url]은 서버가 준 다운로드 경로, [localPath]는 아직 안 보낸 녹음의 파일 경로다.
  Future<void> toggle({
    required String messageId,
    String? url,
    String? localPath,
    Duration? knownDuration,
  }) async {
    if (state.isActive(messageId)) {
      if (state.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    // 다른 걸 듣고 있었다면 멈춘다.
    await _player.stop();
    state = VoicePlaybackState(
      messageId: messageId,
      duration: knownDuration ?? Duration.zero,
      loading: true,
    );

    try {
      final path = localPath ?? await _download(messageId, url!);
      final real = await _player.setFilePath(path);
      state = VoicePlaybackState(
        messageId: messageId,
        // 실제 파일 길이를 알면 그걸 쓰고, 못 읽으면 서버가 준 값으로 그린다.
        duration: real ?? knownDuration ?? Duration.zero,
      );
      await _player.play();
    } catch (_) {
      // 파일이 없거나 코덱을 못 읽는 경우. 조용히 초기화한다 —
      // 여기서 예외를 던지면 말풍선 빌드가 통째로 깨진다.
      state = const VoicePlaybackState();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = const VoicePlaybackState();
  }

  /// 인증 헤더가 필요해 URL을 플레이어에 바로 못 넘긴다. 받아서 임시 파일로 둔다.
  Future<String> _download(String messageId, String url) async {
    final cached = _cache[messageId];
    if (cached != null && await File(cached).exists()) return cached;

    final bytes = await ref.read(dioClientProvider).getBytes(url);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/voice_recv_$messageId.m4a');
    await file.writeAsBytes(bytes, flush: true);
    _cache[messageId] = file.path;
    return file.path;
  }
}

final voicePlayerProvider =
    NotifierProvider<VoicePlayerController, VoicePlaybackState>(
      VoicePlayerController.new,
    );
