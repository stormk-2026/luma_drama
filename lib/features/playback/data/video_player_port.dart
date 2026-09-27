import 'package:video_player/video_player.dart';

import '../../catalog/domain/drama.dart';
import '../domain/player_port.dart';

class VideoPlayerPort implements PlayerPort {
  VideoPlayerPort(
    Episode episode, {
    Future<ClosedCaptionFile>? closedCaptionFile,
  }) : controller = VideoPlayerController.asset(
         episode.assetPath,
         closedCaptionFile: closedCaptionFile,
         videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
       );

  final VideoPlayerController controller;
  Future<void>? _initialization;
  bool _disposed = false;

  @override
  Future<void> initialize() {
    return _initialization ??= controller.initialize().then((_) async {
      if (!_disposed) await controller.setLooping(false);
    });
  }

  @override
  Future<void> play() async {
    if (!_disposed && controller.value.isInitialized) await controller.play();
  }

  @override
  Future<void> pause() async {
    if (!_disposed && controller.value.isInitialized) await controller.pause();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _initialization;
    } catch (_) {
      // The native controller still needs disposal after failed initialization.
    }
    await controller.dispose();
  }
}
