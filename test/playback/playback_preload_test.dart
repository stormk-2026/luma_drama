import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma_drama/features/catalog/domain/drama.dart';
import 'package:luma_drama/features/playback/application/playback_session.dart';
import 'package:luma_drama/features/playback/domain/player_port.dart';

void main() {
  final episodes = List.generate(
    5,
    (i) => Episode(
      id: 'ep-$i',
      number: i + 1,
      title: 'Episode $i',
      assetPath: 'test-$i.mp4',
      isFree: i < 4,
    ),
  );

  test('warm playback starts before old native disposal finishes', () async {
    final release = Completer<void>();
    final factory = _Factory(disposeGates: {'ep-0': release});
    final session = PlaybackSession(
      episodes: episodes,
      factory: factory.create,
      canPlay: (_) => true,
    );
    await session.select(0, preloadIndex: 1);
    await session.preloadSettled;
    final selection = session.select(1, preloadIndex: 2);
    await _tick();
    expect(factory.players[1].playing, isTrue);
    expect(factory.players[0].playing, isFalse);
    expect(session.loading, isFalse);
    expect(session.livePlayerCount, 2);
    expect(factory.players, hasLength(2));
    release.complete();
    await selection;
    await session.preloadSettled;
    expect(factory.peakLive, 2);
    await session.close();
  });

  test('failed native release blocks another route from allocating', () async {
    final factory = _Factory(disposeFailures: {'ep-0'});
    final coordinator = PlaybackCoordinator();
    PlaybackSession createSession() => PlaybackSession(
      episodes: episodes,
      factory: factory.create,
      canPlay: (_) => true,
      coordinator: coordinator,
    );
    final home = createSession();
    final series = createSession();
    await home.select(0, preloadIndex: 1);
    await home.preloadSettled;
    home.setRouteVisible(false);
    await series.select(2, preloadIndex: 3);
    expect(series.error, isNotNull);
    expect(factory.players, hasLength(2));
    await series.select(2, preloadIndex: 3);
    await series.preloadSettled;
    expect(series.error, isNull);
    expect(factory.peakLive, 2);
    await series.close();
    await home.close();
    expect(factory.live, 0);
  });

  test(
    'next is prepared silently and promoted without another initialize',
    () async {
      final factory = _Factory();
      final prepared = <String>[];
      final activated = <String>[];
      final session = PlaybackSession(
        episodes: episodes,
        factory: factory.create,
        canPlay: (e) => e.isFree,
        prepare: (e, _) async => prepared.add(e.id),
        activate: (e, _) async => activated.add(e.id),
      );
      await session.select(0, preloadIndex: 1);
      await session.preloadSettled;
      final warm = factory.players[1];
      expect(prepared, ['ep-0', 'ep-1']);
      expect(activated, ['ep-0']);
      expect(warm.playCalls, 0);
      expect(session.preloadedIndex, 1);
      final loadingStates = <bool>[];
      session.addListener(() => loadingStates.add(session.loading));
      await session.select(1, preloadIndex: 2);
      await session.preloadSettled;
      expect(session.active, same(warm));
      expect(warm.initializeCalls, 1);
      expect(warm.playCalls, 1);
      expect(loadingStates, isNot(contains(true)));
      expect(activated, ['ep-0', 'ep-1']);
      expect(factory.peakLive, 2);
      expect(factory.peakPlaying, 1);
      await session.close();
      expect(factory.live, 0);
    },
  );

  test('in-flight preload is reused when swiped before ready', () async {
    final gate = Completer<void>();
    final factory = _Factory(gates: {'ep-1': gate});
    final session = PlaybackSession(
      episodes: episodes,
      factory: factory.create,
      canPlay: (_) => true,
    );
    await session.select(0, preloadIndex: 1);
    await _tick();
    final warm = factory.players[1];
    final selection = session.select(1, preloadIndex: 2);
    await _tick();
    expect(session.loading, isTrue);
    gate.complete();
    await selection;
    await session.preloadSettled;
    expect(session.active, same(warm));
    expect(warm.initializeCalls, 1);
    expect(factory.peakLive, lessThanOrEqualTo(2));
    expect(factory.peakPlaying, 1);
    await session.close();
  });

  test('rapid reverse and skipped selection discard stale warm work', () async {
    final gate = Completer<void>();
    final factory = _Factory(gates: {'ep-1': gate});
    final session = PlaybackSession(
      episodes: episodes,
      factory: factory.create,
      canPlay: (_) => true,
    );
    await session.select(0, preloadIndex: 1);
    await _tick();
    final stale = factory.players[1];
    final skip = session.select(3, preloadIndex: 4);
    final reverse = session.select(0, preloadIndex: 2);
    gate.complete();
    await Future.wait([skip, reverse]);
    await session.preloadSettled;
    expect(session.currentIndex, 0);
    expect(session.preloadedIndex, 2);
    expect(stale.playCalls, 0);
    expect(stale.disposed, isTrue);
    expect(factory.peakLive, lessThanOrEqualTo(2));
    expect(factory.peakPlaying, 1);
    await session.close();
  });

  test(
    'category adjacency and locked next never preload the wrong episode',
    () async {
      final factory = _Factory();
      final session = PlaybackSession(
        episodes: episodes,
        factory: factory.create,
        canPlay: (e) => e.isFree,
      );
      await session.select(0, preloadIndex: 2);
      await session.preloadSettled;
      expect(factory.players.map((p) => p.id), ['ep-0', 'ep-2']);
      await session.select(0, preloadIndex: 4);
      await session.preloadSettled;
      expect(session.preloadedIndex, isNull);
      expect(factory.players.any((p) => p.id == 'ep-4'), isFalse);
      await session.close();
    },
  );

  test('preload failure is isolated and selecting it retries once', () async {
    final factory = _Factory(failOnce: {'ep-1'});
    final session = PlaybackSession(
      episodes: episodes,
      factory: factory.create,
      canPlay: (_) => true,
    );
    await session.select(0, preloadIndex: 1);
    await session.preloadSettled;
    expect(session.error, isNull);
    expect(session.loading, isFalse);
    expect(factory.players.first.playing, isTrue);
    await session.select(1);
    expect(session.error, isNull);
    expect(factory.players.where((p) => p.id == 'ep-1'), hasLength(2));
    await session.close();
  });

  test('completion in background never starts either player', () async {
    final gate = Completer<void>();
    final factory = _Factory(gates: {'ep-1': gate});
    final session = PlaybackSession(
      episodes: episodes,
      factory: factory.create,
      canPlay: (_) => true,
    );
    await session.select(0, preloadIndex: 1);
    await _tick();
    final selection = session.select(1, preloadIndex: 2);
    await _tick();
    session.setAppResumed(false);
    gate.complete();
    await selection;
    await session.preloadSettled;
    expect(factory.players.every((p) => !p.playing), isTrue);
    expect(factory.players.any((p) => p.id == 'ep-2'), isFalse);
    session.setUserWantsPlay(false);
    session.setAppResumed(true);
    await session.playbackSettled;
    expect(factory.players.every((p) => !p.playing), isTrue);
    await session.close();
  });

  test('closing during preloading disposes pending resources', () async {
    final gate = Completer<void>();
    final factory = _Factory(gates: {'ep-1': gate});
    final session = PlaybackSession(
      episodes: episodes,
      factory: factory.create,
      canPlay: (_) => true,
    );
    await session.select(0, preloadIndex: 1);
    await _tick();
    final closed = session.close();
    gate.complete();
    await closed;
    expect(factory.live, 0);
    expect(factory.players.last.playCalls, 0);
  });

  test(
    'home and series share a two-player budget across route handoff',
    () async {
      final factory = _Factory();
      final coordinator = PlaybackCoordinator();
      PlaybackSession createSession() => PlaybackSession(
        episodes: episodes,
        factory: factory.create,
        canPlay: (_) => true,
        coordinator: coordinator,
      );
      final home = createSession();
      final series = createSession();
      await home.select(0, preloadIndex: 1);
      await home.preloadSettled;
      home.setRouteVisible(false);
      await series.select(2, preloadIndex: 3);
      await series.preloadSettled;
      expect(home.livePlayerCount, 0);
      expect(factory.peakLive, 2);
      expect(factory.peakPlaying, 1);
      await series.close();
      home.setRouteVisible(true);
      await _tick();
      await home.playbackSettled;
      await home.preloadSettled;
      expect(home.active, isNotNull);
      expect(factory.peakLive, 2);
      await home.close();
      expect(factory.live, 0);
    },
  );
}

Future<void> _tick() => Future<void>.delayed(Duration.zero);

class _Factory {
  _Factory({
    this.gates = const {},
    this.disposeGates = const {},
    Set<String>? failOnce,
    Set<String>? disposeFailures,
  }) : failures = failOnce ?? {},
       disposeFailures = disposeFailures ?? {};
  final Map<String, Completer<void>> gates;
  final Map<String, Completer<void>> disposeGates;
  final Set<String> disposeFailures;
  final Set<String> failures;
  final List<_Player> players = [];
  int live = 0;
  int peakLive = 0;
  int peakPlaying = 0;

  PlayerPort create(Episode episode) {
    live++;
    if (live > peakLive) peakLive = live;
    final player = _Player(
      episode.id,
      this,
      gates[episode.id],
      failures.remove(episode.id),
    );
    players.add(player);
    return player;
  }
}

class _Player implements PlayerPort {
  _Player(this.id, this.factory, this.gate, this.fail);
  final String id;
  final _Factory factory;
  final Completer<void>? gate;
  final bool fail;
  bool playing = false;
  bool disposed = false;
  int initializeCalls = 0;
  int playCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    await gate?.future;
    if (fail) throw StateError('Test initialization failed');
  }

  @override
  Future<void> play() async {
    expect(disposed, isFalse);
    playCalls++;
    playing = true;
    final count = factory.players.where((p) => p.playing).length;
    if (count > factory.peakPlaying) factory.peakPlaying = count;
  }

  @override
  Future<void> pause() async => playing = false;

  @override
  Future<void> dispose() async {
    if (disposed) return;
    await gate?.future;
    await factory.disposeGates[id]?.future;
    if (factory.disposeFailures.remove(id)) {
      throw StateError('Test disposal failed');
    }
    disposed = true;
    playing = false;
    factory.live--;
  }
}
