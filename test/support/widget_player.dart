import 'package:luma_drama/features/catalog/domain/drama.dart';
import 'package:luma_drama/features/playback/domain/player_port.dart';

// Widget tests exercise navigation and scheduling without a native decoder.
PlayerPort createWidgetPlayer(Episode episode) => WidgetPlayer();

class WidgetPlayer implements PlayerPort {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> dispose() async {}
}
