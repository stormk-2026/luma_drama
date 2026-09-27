import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma_drama/features/catalog/domain/drama.dart';
import 'package:luma_drama/features/playback/application/playback_session.dart';
import 'package:luma_drama/features/playback/domain/player_port.dart';

void main() {
  final episodes = List.generate(
    4,
    (i) => Episode(
      id: 'ep-${i + 1}',
      number: i + 1,
      title: 'Episode ${i + 1}',
      assetPath: 'assets/media/episode_0${i + 1}.mp4',
      isFree: i < 2,
    ),
  );

  test('locked episode never creates or initializes a player', () async {
    final factory = FakeFactory();
    final session = PlaybackSession(
      episodes: episodes,
      factory: factory.create,
      canPlay: (episode) => episode.isFree,
    );
    await session.select(2);
    expect(session.isLocked, isTrue);
    expect(factory.created, isEmpty);
    await session.close();
  });

  test('rapid selection drops stale initialize and keeps one player', () async {
    final factory = FakeFactory(holdFirstInitialize: true);
    final session = PlaybackSession(
      episodes: episodes,
      factory: factory.create,
      canPlay: (episode) => episode.isFree,
    );
    final first = session.select(0);
    await factory.firstCreated.future;
    final second = session.select(1);
    factory.created.first.releaseInitialize();
    await Future.wait([first, second]);
    expect(factory.peakLive, lessThanOrEqualTo(1));
    expect(factory.created.first.playCalls, 0);
    expect(factory.created.first.disposed, isTrue);
    expect(session.currentIndex, 1);
    expect(factory.created.last.playCalls, 1);
    await session.close();
    expect(factory.live, 0);
  });

  test(
    'background and overlay pause without forgetting playback intent',
    () async {
      final factory = FakeFactory();
      final session = PlaybackSession(
        episodes: episodes,
        factory: factory.create,
        canPlay: (episode) => episode.isFree,
      );
      await session.select(0);
      final player = factory.created.single;
      expect(player.playCalls, 1);
      session.setAppResumed(false);
      await Future<void>.delayed(Duration.zero);
      expect(player.pauseCalls, 1);
      session.setAppResumed(true);
      await Future<void>.delayed(Duration.zero);
      expect(player.playCalls, 2);
      session.setOverlayOpen(true);
      await Future<void>.delayed(Duration.zero);
      expect(player.pauseCalls, 2);
      session.setUserWantsPlay(false);
      session.setOverlayOpen(false);
      await Future<void>.delayed(Duration.zero);
      expect(player.playCalls, 2);
      await session.close();
    },
  );

  test('resume preparation finishes before video starts', () async {
    final factory = FakeFactory();
    final prepared = Completer<void>();
    final session = PlaybackSession(
      episodes: episodes,
      factory: factory.create,
      canPlay: (episode) => episode.isFree,
      prepare: (_, _) => prepared.future,
    );
    final selection = session.select(0);
    await factory.firstCreated.future;
    await Future<void>.delayed(Duration.zero);
    expect(factory.created.single.playCalls, 0);
    prepared.complete();
    await selection;
    expect(factory.created.single.playCalls, 1);
    await session.close();
  });

  test('automatic advance respects visibility and playback intent', () async {
    final factory = FakeFactory();
    final session = PlaybackSession(
      episodes: episodes,
      factory: factory.create,
      canPlay: (episode) => episode.isFree,
    );
    await session.select(0);
    expect(session.canAutoAdvance, isTrue);
    session.setRouteVisible(false);
    expect(session.canAutoAdvance, isFalse);
    session.setRouteVisible(true);
    session.setOverlayOpen(true);
    expect(session.canAutoAdvance, isFalse);
    session.setOverlayOpen(false);
    session.setUserWantsPlay(false);
    expect(session.canAutoAdvance, isFalse);
    await session.close();
  });
}

class FakeFactory {
  FakeFactory({this.holdFirstInitialize = false});
  final bool holdFirstInitialize;
  final List<FakePlayer> created = [];
  final Completer<void> firstCreated = Completer<void>();
  int live = 0;
  int peakLive = 0;

  PlayerPort create(Episode episode) {
    live++;
    if (live > peakLive) peakLive = live;
    final player = FakePlayer(
      holdInitialize: holdFirstInitialize && created.isEmpty,
      onDispose: () => live--,
    );
    created.add(player);
    if (!firstCreated.isCompleted) firstCreated.complete();
    return player;
  }
}

class FakePlayer implements PlayerPort {
  FakePlayer({required this.holdInitialize, required this.onDispose});
  final bool holdInitialize;
  final void Function() onDispose;
  final Completer<void> _initializeGate = Completer<void>();
  bool initialized = false;
  bool disposed = false;
  int playCalls = 0;
  int pauseCalls = 0;

  void releaseInitialize() => _initializeGate.complete();

  @override
  Future<void> initialize() async {
    if (holdInitialize) await _initializeGate.future;
    initialized = true;
  }

  @override
  Future<void> play() async => playCalls++;

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    onDispose();
  }
}
