import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Keeps seeks within the playable range so dragging to the edge does not
/// trigger the player's completion callback before playback resumes.
Duration seekPositionForFraction(double fraction, Duration duration) {
  final total = duration.inMilliseconds;
  if (total <= 0) return Duration.zero;
  final lastPlayable = total > 250 ? total - 250 : total - 1;
  final requested = (fraction.clamp(0.0, 1.0) * total).round();
  return Duration(milliseconds: requested.clamp(0, lastPlayable));
}

class SeekProgressBar extends StatefulWidget {
  const SeekProgressBar({
    super.key,
    required this.valueListenable,
    required this.semanticsLabel,
    this.onScrubStart,
    this.onSeek,
    this.showTimes = true,
    this.compactIdle = false,
  });

  final ValueListenable<VideoPlayerValue>? valueListenable;
  final String semanticsLabel;
  final VoidCallback? onScrubStart;
  final Future<void> Function(Duration)? onSeek;
  final bool showTimes;
  final bool compactIdle;

  @override
  State<SeekProgressBar> createState() => _SeekProgressBarState();
}

class _SeekProgressBarState extends State<SeekProgressBar> {
  double? _previewFraction;

  @override
  void didUpdateWidget(covariant SeekProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueListenable != widget.valueListenable) {
      _previewFraction = null;
    }
  }

  Future<void> _finish(double fraction, Duration duration) async {
    final source = widget.valueListenable;
    setState(() => _previewFraction = fraction);
    try {
      await widget.onSeek?.call(seekPositionForFraction(fraction, duration));
    } finally {
      if (mounted && widget.valueListenable == source) {
        setState(() => _previewFraction = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.valueListenable;
    if (source == null) {
      return _buildTrack(context, const VideoPlayerValue.uninitialized());
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: source,
      builder: (context, value, _) => _buildTrack(context, value),
    );
  }

  Widget _buildTrack(BuildContext context, VideoPlayerValue video) {
    final total = video.duration.inMilliseconds;
    final enabled = video.isInitialized && total > 0 && widget.onSeek != null;
    final played = total > 0
        ? (video.position.inMilliseconds / total).clamp(0.0, 1.0)
        : 0.0;
    final fraction = _previewFraction ?? played;
    final previewPosition = _previewFraction == null
        ? video.position
        : seekPositionForFraction(fraction, video.duration);
    final scrubbing = _previewFraction != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.compactIdle && !scrubbing ? 20 : 36,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: widget.compactIdle && !scrubbing ? 2 : 3,
              activeTrackColor: const Color(0xFFFF5C37),
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.white,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: widget.compactIdle && !scrubbing ? 0 : 6,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: widget.compactIdle && !scrubbing ? 0 : 11,
              ),
            ),
            child: Semantics(
              label: widget.semanticsLabel,
              child: Slider(
                value: fraction,
                onChangeStart: enabled
                    ? (value) {
                        setState(() => _previewFraction = value);
                        widget.onScrubStart?.call();
                      }
                    : null,
                onChanged: enabled
                    ? (value) => setState(() => _previewFraction = value)
                    : null,
                onChangeEnd: enabled
                    ? (value) => unawaited(_finish(value, video.duration))
                    : null,
              ),
            ),
          ),
        ),
        if (widget.showTimes && (!widget.compactIdle || scrubbing))
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(previewPosition),
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
              Text(
                _format(video.duration),
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ],
          ),
      ],
    );
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
