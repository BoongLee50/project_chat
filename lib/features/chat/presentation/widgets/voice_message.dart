import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/chat_models.dart';
import '../providers/voice_player.dart';
import '../providers/voice_recorder.dart';

/// 파형 막대. 재생 진행도만큼 색이 채워진다.
///
/// ⚠️ **실제 오디오를 분석한 파형이 아니다.** 진짜 파형을 그리려면 파일을 PCM으로
/// 디코딩해 구간별 진폭을 구해야 하는데, 말풍선 하나마다 그 비용을 치를 이유가 없다.
/// 대신 **메시지 id로 만든 고정 난수**를 쓴다 — 메시지마다 모양이 다르고,
/// 같은 메시지는 언제 봐도 같은 모양이다(다시 그릴 때 출렁이지 않는다).
class _WaveBars extends StatelessWidget {
  const _WaveBars({
    required this.seed,
    required this.progress,
    required this.activeColor,
    required this.baseColor,
  });

  final int seed;
  final double progress;
  final Color activeColor;
  final Color baseColor;

  /// 막대 개수. 말풍선과 녹음 바가 같은 밀도로 보이도록 한곳에 고정한다.
  static const barCount = 34;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bars = <Widget>[];
        for (var i = 0; i < barCount; i++) {
          // 선형 합동 생성기 한 스텝. 난수 품질은 중요하지 않고 재현성만 필요하다.
          final n = (seed + i * 2654435761) % 1000;
          final height = 6 + (n % 18).toDouble();
          final filled = (i + 1) / barCount <= progress;
          bars.add(
            Container(
              width: 2.5,
              height: height,
              decoration: BoxDecoration(
                color: filled ? activeColor : baseColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: bars,
        );
      },
    );
  }
}

String formatVoiceDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// 말풍선 안에 들어가는 음성 메시지 본문 — 재생 버튼 + 파형 + 길이.
class VoiceBubbleContent extends ConsumerWidget {
  const VoiceBubbleContent({
    super.key,
    required this.message,
    required this.foreground,
  });

  final ChatMessage message;

  /// 말풍선 배경에 맞춘 글자·아이콘 색.
  final Color foreground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(voicePlayerProvider);
    final active = playback.isActive(message.id);
    final total = Duration(milliseconds: message.audioDurationMs ?? 0);

    // 재생 중이면 남은 시간을, 아니면 전체 길이를 보여준다(메신저 관행).
    final shown = active && playback.duration > Duration.zero
        ? playback.duration - playback.position
        : total;

    return SizedBox(
      width: 210,
      child: Row(
        children: [
          _PlayButton(
            playing: active && playback.playing,
            loading: active && playback.loading,
            color: foreground,
            onTap: () => ref
                .read(voicePlayerProvider.notifier)
                .toggle(
                  messageId: message.id,
                  url: message.audioUrl,
                  knownDuration: total,
                ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 26,
              child: _WaveBars(
                seed: message.id.hashCode.abs(),
                progress: active ? playback.progress : 0,
                activeColor: foreground,
                baseColor: foreground.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatVoiceDuration(shown),
            style: TextStyle(
              color: foreground.withValues(alpha: 0.75),
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.loading,
    required this.color,
    required this.onTap,
  });

  final bool playing;
  final bool loading;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(9),
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              : Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: color,
                  size: 20,
                ),
        ),
      ),
    );
  }
}

/// 입력창 자리를 대신하는 녹음 바 — 녹음 중 / 미리듣기 두 모습.
///
/// 기획 화면의 3단(기본·녹음 중·미리듣기) 중 뒤의 둘을 담당한다.
/// 기본 상태(마이크 버튼)는 입력창 쪽에 있다.
class VoiceRecordBar extends ConsumerWidget {
  const VoiceRecordBar({super.key, required this.onSend, required this.busy});

  final VoidCallback onSend;

  /// 전송 중 — 버튼을 눌러도 두 번 보내지지 않게 막는다.
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final rec = ref.watch(voiceRecorderProvider);
    final recorder = ref.read(voiceRecorderProvider.notifier);
    final playback = ref.watch(voicePlayerProvider);

    final recording = rec.isRecording;
    const previewId = '__recording_preview__';
    final previewActive = playback.isActive(previewId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          // 미리듣기 단계에서만 삭제 버튼. 녹음 중에는 자리를 비운다.
          if (!recording)
            _RoundButton(
              icon: Icons.delete_outline,
              tooltip: l10n.voiceDelete,
              onTap: busy ? null : () => recorder.discard(),
            ),
          if (!recording) const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 30,
              child: recording
                  ? _LiveWave(amplitude: rec.amplitude)
                  : _WaveBars(
                      seed: rec.filePath.hashCode.abs(),
                      progress: previewActive ? playback.progress : 0,
                      activeColor: AppColors.moonlight,
                      baseColor: AppColors.textMuted,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatVoiceDuration(rec.elapsed),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          if (recording)
            _RoundButton(
              icon: Icons.stop,
              tooltip: l10n.voiceStop,
              filled: true,
              onTap: () => recorder.stop(),
            )
          else ...[
            _RoundButton(
              icon: previewActive && playback.playing
                  ? Icons.pause
                  : Icons.play_arrow,
              tooltip: l10n.voicePlay,
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
            const SizedBox(width: 8),
            _RoundButton(
              icon: Icons.arrow_upward,
              tooltip: l10n.voiceSend,
              accent: true,
              busy: busy,
              onTap: busy ? null : onSend,
            ),
          ],
        ],
      ),
    );
  }
}

/// 녹음 중 파형 — 입력 크기에 따라 가운데가 부풀었다 줄었다 한다.
///
/// 지나간 소리를 밀어 담는 방식이 더 그럴듯하지만, 그러려면 진폭 이력을
/// 상태로 들고 있어야 해서 프레임마다 리스트가 다시 만들어진다.
/// 지금 값 하나로 전체를 흔드는 편이 가볍고, 녹음 중이라는 신호로는 충분하다.
class _LiveWave extends StatelessWidget {
  const _LiveWave({required this.amplitude});

  final double amplitude;

  @override
  Widget build(BuildContext context) {
    const count = 34;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 2.5,
            // 가운데일수록 크게 — 가장자리는 잔잔하게 둬야 파형처럼 보인다.
            height: 4 + 22 * amplitude * _centerWeight(i, count),
            decoration: BoxDecoration(
              color: AppColors.moonlight,
              borderRadius: BorderRadius.circular(2),
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
    this.accent = false,
    this.busy = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  /// 정지 버튼 — 네모난 채움으로 눈에 띄게.
  final bool filled;

  /// 올리기 버튼 — 강조색 원형.
  final bool accent;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    // 정지(filled)는 밝은 원 + 어두운 아이콘이다. 배경과 아이콘을 둘 다 흰색으로 두면
    // 버튼이 빈 동그라미로 보인다.
    final background = accent
        ? AppColors.moonlight
        : (filled ? AppColors.textPrimary : AppColors.surfaceHigh);
    final foreground = accent
        ? Colors.white
        : (filled ? AppColors.night : AppColors.textSecondary);

    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 38,
              height: 38,
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, color: foreground, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
