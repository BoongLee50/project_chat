import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// 음성 메시지 녹음.
///
/// 화면은 세 모습을 가진다(기획 화면 참고) — 기본 / 녹음 중 / 미리듣기.
/// 그 셋을 [VoiceRecordPhase] 하나로 표현하고, 화면은 이 상태만 보고 그린다.
enum VoiceRecordPhase {
  /// 마이크 버튼만 보이는 평소 상태.
  idle,

  /// 녹음 중 — 정지 버튼과 경과 시간을 보여준다.
  recording,

  /// 녹음이 끝나 파일이 손에 있는 상태 — 듣기·삭제·올리기.
  preview,
}

class VoiceRecordState {
  const VoiceRecordState({
    this.phase = VoiceRecordPhase.idle,
    this.elapsed = Duration.zero,
    this.amplitude = 0,
    this.filePath,
  });

  final VoiceRecordPhase phase;

  /// 녹음 중이면 경과 시간, 미리듣기면 녹음된 길이.
  final Duration elapsed;

  /// 0~1로 정규화한 입력 크기. 파형을 그리는 데만 쓴다.
  final double amplitude;

  /// 녹음 결과 파일. 미리듣기 단계에서만 채워진다.
  final String? filePath;

  bool get isRecording => phase == VoiceRecordPhase.recording;
  bool get hasTake => phase == VoiceRecordPhase.preview && filePath != null;

  VoiceRecordState copyWith({
    VoiceRecordPhase? phase,
    Duration? elapsed,
    double? amplitude,
    String? filePath,
    bool clearFile = false,
  }) => VoiceRecordState(
    phase: phase ?? this.phase,
    elapsed: elapsed ?? this.elapsed,
    amplitude: amplitude ?? this.amplitude,
    filePath: clearFile ? null : (filePath ?? this.filePath),
  );
}

/// 녹음 최대 길이. 서버도 같은 값으로 검사하므로 **함께 바꿔야 한다**
/// (`app.chat.voice-max-duration-ms`). 여기서 먼저 멈춰 주지 않으면
/// 길게 녹음한 뒤 전송 단계에서야 거부돼 녹음이 통째로 버려진다.
const kVoiceMaxDuration = Duration(seconds: 30);

class VoiceRecorderController extends Notifier<VoiceRecordState> {
  final _recorder = AudioRecorder();
  Timer? _ticker;
  StreamSubscription<Amplitude>? _amplitudeSub;
  DateTime? _startedAt;

  @override
  VoiceRecordState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _amplitudeSub?.cancel();
      _recorder.dispose();
    });
    return const VoiceRecordState();
  }

  /// 녹음 시작. 마이크 권한이 없으면 false — 화면이 안내를 띄운다.
  Future<bool> start() async {
    if (state.isRecording) return true;
    if (!await _recorder.hasPermission()) return false;

    // 임시 폴더에 둔다. 보내고 나면 지우고, 앱이 죽어도 OS가 정리한다.
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      // AAC/m4a는 안드로이드·iOS 양쪽이 기본으로 재생할 수 있고 용량도 작다.
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );

    _startedAt = DateTime.now();
    state = VoiceRecordState(
      phase: VoiceRecordPhase.recording,
      filePath: path,
    );

    // 경과 시간은 타이머가 아니라 **시작 시각과의 차이**로 센다.
    // 타이머 콜백은 밀릴 수 있어 누적하면 실제보다 짧게 표시된다.
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final started = _startedAt;
      if (started == null) return;
      final elapsed = DateTime.now().difference(started);
      if (elapsed >= kVoiceMaxDuration) {
        stop(); // 최대 길이에서 자동 정지
        return;
      }
      state = state.copyWith(elapsed: elapsed);
    });

    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((amp) {
          state = state.copyWith(amplitude: _normalize(amp.current));
        });
    return true;
  }

  /// 녹음 종료 → 미리듣기 단계로.
  Future<void> stop() async {
    if (!state.isRecording) return;
    _ticker?.cancel();
    _amplitudeSub?.cancel();
    _ticker = null;
    _amplitudeSub = null;

    final path = await _recorder.stop();
    final started = _startedAt;
    _startedAt = null;

    var elapsed = started == null
        ? state.elapsed
        : DateTime.now().difference(started);
    if (elapsed > kVoiceMaxDuration) elapsed = kVoiceMaxDuration;

    if (path == null) {
      state = const VoiceRecordState();
      return;
    }
    state = VoiceRecordState(
      phase: VoiceRecordPhase.preview,
      elapsed: elapsed,
      filePath: path,
    );
  }

  /// 녹음 결과 폐기(삭제 버튼). 파일도 지운다.
  Future<void> discard() async {
    if (state.isRecording) {
      _ticker?.cancel();
      _amplitudeSub?.cancel();
      _ticker = null;
      _amplitudeSub = null;
      _startedAt = null;
      await _recorder.stop();
    }
    final path = state.filePath;
    state = const VoiceRecordState();
    if (path != null) {
      // 지우기 실패는 무시한다 — 임시 폴더라 OS가 결국 정리한다.
      try {
        await File(path).delete();
      } on FileSystemException {
        // 이미 없거나 접근 불가. 사용자에게 알릴 일이 아니다.
      }
    }
  }

  /// 전송용 바이트를 꺼낸다. 꺼낸 뒤에도 상태는 그대로 두고,
  /// 전송이 성공한 다음에 [discard]로 정리한다(실패 시 다시 보낼 수 있게).
  Future<List<int>?> readBytes() async {
    final path = state.filePath;
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  /// dBFS(-160~0)를 0~1로. -45dB 아래는 사실상 무음이라 바닥으로 본다.
  double _normalize(double dbfs) {
    const floor = -45.0;
    if (dbfs.isNaN || dbfs <= floor) return 0;
    if (dbfs >= 0) return 1;
    return (dbfs - floor) / -floor;
  }
}

final voiceRecorderProvider =
    NotifierProvider<VoiceRecorderController, VoiceRecordState>(
      VoiceRecorderController.new,
    );
