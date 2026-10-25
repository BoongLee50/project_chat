import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/chat_models.dart';
import '../providers/voice_player.dart';
import '../providers/voice_recorder.dart';
import 'chat_art.dart';

/// 파형 막대. 재생 진행도만큼 진하게 채워진다.
///
/// ⚠️ **실제 오디오를 분석한 파형이 아니다.** 진짜 파형을 그리려면 파일을 PCM으로
/// 디코딩해 구간별 진폭을 구해야 하는데, 말풍선 하나마다 그 비용을 치를 이유가 없다.
/// 대신 **메시지 id로 만든 고정 난수**를 쓴다 — 메시지마다 모양이 다르고,
/// 같은 메시지는 언제 봐도 같은 모양이다(다시 그릴 때 출렁이지 않는다).
///
/// 시안(`채팅창 참고 화면.png`)은 낮은 점이 깔리고 군데군데 높은 막대가 솟는 모양이라
/// 높이를 고르게 흩지 않고 **대부분 낮게, 가끔 높게** 뽑는다.
class _WaveBars extends StatelessWidget {
  const _WaveBars({
    required this.seed,
    required this.progress,
    required this.scale,
  });

  final int seed;
  final double progress;
  final double scale;

  /// 막대 개수. 말풍선과 입력칸이 같은 밀도로 보이도록 한곳에 고정한다.
  static const barCount = 40;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final bars = <Widget>[];
    for (var i = 0; i < barCount; i++) {
      // 선형 합동 생성기 한 스텝. 난수 품질은 중요하지 않고 재현성만 필요하다.
      final n = (seed + i * 2654435761) % 1000;
      final tall = n % 5 == 0;
      final height = tall ? 26 + (n % 40) : 6 + (n % 4) * 5;
      final filled = progress > 0 && (i + 1) / barCount <= progress;
      bars.add(
        Container(
          width: 4 * s,
          height: height * s,
          decoration: BoxDecoration(
            color: filled
                ? ChatArt.waveInk
                : ChatArt.waveInk.withValues(alpha: progress > 0 ? 0.35 : 1),
            borderRadius: BorderRadius.circular(2 * s),
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: bars,
    );
  }
}

String formatVoiceDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

TextStyle _durationStyle(double s) => TextStyle(
  color: ChatArt.waveInk,
  fontSize: ChatArt.durationFont * s,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// 말풍선 안에 들어가는 음성 메시지 본문 — [▶] + 파형 + 길이(시안 `155, 1427`).
class VoiceBubbleContent extends ConsumerWidget {
  const VoiceBubbleContent({
    super.key,
    required this.message,
    required this.scale,
  });

  final ChatMessage message;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = scale;
    final playback = ref.watch(voicePlayerProvider);
    final active = playback.isActive(message.id);
    final total = Duration(milliseconds: message.audioDurationMs ?? 0);

    // 재생 중이면 남은 시간을, 아니면 전체 길이를 보여준다(메신저 관행).
    final shown = active && playback.duration > Duration.zero
        ? playback.duration - playback.position
        : total;

    final inner =
        ChatArt.voiceBubbleWidth -
        ChatArt.voicePad.horizontal;

    return SizedBox(
      width: inner * s,
      child: Row(
        children: [
          VoicePlayButton(
            playing: active && playback.playing,
            loading: active && playback.loading,
            scale: s,
            onTap: () => ref
                .read(voicePlayerProvider.notifier)
                .toggle(
                  messageId: message.id,
                  url: message.audioUrl,
                  knownDuration: total,
                ),
          ),
          SizedBox(width: ChatArt.playToWave * s),
          Expanded(
            child: SizedBox(
              height: ChatArt.waveHeight * s,
              child: _WaveBars(
                seed: message.id.hashCode.abs(),
                progress: active ? playback.progress : 0,
                scale: s,
              ),
            ),
          ),
          SizedBox(width: 18 * s),
          Text(formatVoiceDuration(shown), style: _durationStyle(s)),
        ],
      ),
    );
  }
}

/// [▶] / [Ⅱ] — `button_playback` · `button_playstop`(108). 받는 중에는 그 위에 고리를 돌린다.
class VoicePlayButton extends StatelessWidget {
  const VoicePlayButton({
    super.key,
    required this.playing,
    required this.loading,
    required this.scale,
    required this.onTap,
  });

  final bool playing;
  final bool loading;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final size = ChatArt.playSize * scale;
    return Semantics(
      button: true,
      label: playing ? l10n.voiceStop : l10n.voicePlay,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                playing ? ChatArt.pause : ChatArt.play,
                width: size,
                height: size,
                filterQuality: FilterQuality.medium,
              ),
              if (loading)
                SizedBox(
                  width: size,
                  height: size,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 입력칸(`frame_chatmessage`) 안쪽 — 녹음 중 / 미리듣기 두 모습.
///
/// 기획서 5장 *"음성 녹음 진행 시 입력부에 실시간 오디오 파형 출력"* · *"메시지 입력부에 [녹음 재생] 버튼 생성"*.
/// 좌우 버튼([녹음 삭제]·[정지]·[보내기])은 입력줄이 그린다 — 이 위젯은 칸 안만 맡는다.
class VoiceRecordInside extends ConsumerWidget {
  const VoiceRecordInside({super.key, required this.scale, required this.busy});

  final double scale;

  /// 전송 중 — 미리듣기를 눌러도 반응하지 않는다.
  final bool busy;

  /// 미리듣기는 메시지가 아니라서 id 대신 이 자리표를 쓴다.
  static const previewId = '__recording_preview__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = scale;
    final rec = ref.watch(voiceRecorderProvider);
    final playback = ref.watch(voicePlayerProvider);
    final recording = rec.isRecording;
    final previewActive = playback.isActive(previewId);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: ChatArt.waveHeight * s,
            child: recording
                ? _LiveWave(amplitude: rec.amplitude, scale: s)
                : _WaveBars(
                    seed: rec.filePath.hashCode.abs(),
                    progress: previewActive ? playback.progress : 0,
                    scale: s,
                  ),
          ),
        ),
        SizedBox(width: 18 * s),
        Text(formatVoiceDuration(rec.elapsed), style: _durationStyle(s)),
        if (!recording) ...[
          SizedBox(width: 18 * s),
          VoicePlayButton(
            playing: previewActive && playback.playing,
            loading: false,
            scale: s,
            onTap: busy
                ? null
                : () => ref
                      .read(voicePlayerProvider.notifier)
                      .toggle(
                        messageId: previewId,
                        localPath: rec.filePath,
                        knownDuration: rec.elapsed,
                      ),
          ),
        ],
      ],
    );
  }
}

/// 녹음 중 파형 — 입력 크기에 따라 가운데가 부풀었다 줄었다 한다.
///
/// 지나간 소리를 밀어 담는 방식이 더 그럴듯하지만, 그러려면 진폭 이력을
/// 상태로 들고 있어야 해서 프레임마다 리스트가 다시 만들어진다.
/// 지금 값 하나로 전체를 흔드는 편이 가볍고, 녹음 중이라는 신호로는 충분하다.
class _LiveWave extends StatelessWidget {
  const _LiveWave({required this.amplitude, required this.scale});

  final double amplitude;
  final double scale;

  @override
  Widget build(BuildContext context) {
    const count = _WaveBars.barCount;
    final s = scale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 4 * s,
            // 가운데일수록 크게 — 가장자리는 잔잔하게 둬야 파형처럼 보인다.
            height: (6 + 60 * amplitude * _centerWeight(i, count)) * s,
            decoration: BoxDecoration(
              color: ChatArt.waveInk,
              borderRadius: BorderRadius.circular(2 * s),
            ),
          ),
      ],
    );
  }

  double _centerWeight(int i, int count) {
    final d = (i - (count - 1) / 2).abs() / ((count - 1) / 2);
    return 0.35 + 0.65 * (1 - d * d);
  }
}
