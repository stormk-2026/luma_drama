import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../catalog/domain/drama.dart';
import '../domain/player_port.dart';

typedef PlayerFactory = PlayerPort Function(Episode episode);
typedef PlayerPreparation =
    Future<void> Function(Episode episode, PlayerPort player);

/// Shared by routes: the previous session releases all native players before
/// another session allocates. The app therefore has at most two, not two per page.
class PlaybackCoordinator {
  PlaybackSession? _owner;
  Future<void> _handoff = Future<void>.value();

  Future<bool> _acquire(PlaybackSession session, bool Function() valid) {
    final result = _handoff.then((_) async {
      if (!valid()) return false;
      if (_owner != session) {
        final previous = _owner;
        await previous?._releasePlayers();
        // A failed native disposal cannot be treated as a free decoder slot.
        if (previous != null && previous.livePlayerCount != 0) return false;
        _owner = null;
        if (!valid()) return false;
        _owner = session;
      }
      return true;
    });
    _handoff = result.then<void>((_) {});
    return result;
  }

  void _forget(PlaybackSession session) {
    if (_owner == session && session.livePlayerCount == 0) _owner = null;
  }
}

/// Owns current + one prepared successor. All allocation, playback and disposal
/// operations are serialized; initialization can run while current plays.
class PlaybackSession extends ChangeNotifier {
  PlaybackSession({
    required this.episodes,
    required this.factory,
    required this.canPlay,
    this.prepare,
    this.activate,
    PlaybackCoordinator? coordinator,
  }) : _coordinator = coordinator ?? PlaybackCoordinator();

  final List<Episode> episodes;
  final PlayerFactory factory;
  final bool Function(Episode) canPlay;

  /// Runs once before readiness, also for silent preloads (e.g. resume seek).
  final PlayerPreparation? prepare;

  /// Runs only when a slot becomes current (e.g. progress listeners).
  final PlayerPreparation? activate;
  final PlaybackCoordinator _coordinator;
  final Set<_PlayerSlot> _live = {};
  _PlayerSlot? _active;
  _PlayerSlot? _next;
  Future<void> _operations = Future<void>.value();
  Future<void> _preloadTask = Future<void>.value();
  int _generation = 0;
  int _currentIndex = 0;
  int? _nextIndex;
  bool _selected = false;
  bool _loading = false;
  bool _closed = false;
  bool _appResumed = true;
  bool _routeVisible = true;
  bool _overlayOpen = false;
  bool _userWantsPlay = true;
  String? _error;

  int get currentIndex => _currentIndex;
  Episode get currentEpisode => episodes[_currentIndex];
  PlayerPort? get active =>
      _active?.index == _currentIndex ? _active?.player : null;
  bool get loading => _loading;
  bool get userWantsPlay => _userWantsPlay;
  bool get canAutoAdvance => _mayPlay && !_loading && active != null;
  bool get isLocked => !canPlay(currentEpisode);
  String? get error => _error;
  // Includes initialization and asynchronous disposal, until native release ends.
  int get livePlayerCount => _live.length;
  int? get preloadedIndex => _next?.prepared == true ? _next?.index : null;
  Future<void> get playbackSettled => _operations;
  Future<void> get preloadSettled => _preloadTask;

  bool get _visible => !_closed && _appResumed && _routeVisible;
  bool get _mayPlay => _visible && !_overlayOpen && _userWantsPlay;

  /// Exposes only prepared slots so the adjacent page can mount its video texture
  /// during a swipe without starting audio or registering history listeners.
  PlayerPort? preparedPlayerAt(int index) {
    for (final slot in [_active, _next]) {
      if (slot?.index == index && slot!.prepared) return slot.player;
    }
    return null;
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final task = _operations.then((_) => operation());
    // A plugin failure must not poison subsequent transitions or cleanup.
    _operations = task.catchError((Object error) {
      if (!_closed) {
        _error = error.toString();
        _loading = false;
        _notify();
      }
    });
    return _operations;
  }

  _PlayerSlot _create(int index) {
    if (_live.length >= 2) throw StateError('Playback resource limit reached');
    final slot = _PlayerSlot(index, factory(episodes[index]));
    _live.add(slot);
    slot.ready = () async {
      try {
        await slot.player.initialize();
        if (slot.retiring || _closed) return;
        await prepare?.call(episodes[index], slot.player);
        if (!slot.retiring && !_closed) slot.prepared = true;
      } catch (error) {
        slot.failure = error;
      }
    }();
    return slot;
  }

  Future<void> _retire(_PlayerSlot? slot) async {
    if (slot == null || !_live.contains(slot)) return;
    slot.retiring = true;
    await slot.ready;
    try {
      await slot.player.pause();
    } finally {
      await slot.player.dispose();
      _live.remove(slot);
    }
  }

  /// preloadIndex comes from the visible queue, so filtered categories and series
  /// use exactly the same mechanism without warming an unrelated episode.
  Future<void> select(int index, {int? preloadIndex}) async {
    if (_closed || index < 0 || index >= episodes.length) return;
    final request = ++_generation;
    _selected = true;
    _currentIndex = index;
    _nextIndex = preloadIndex;
    _error = null;
    _loading = preparedPlayerAt(index) == null && !isLocked;
    _notify();
    if (!_visible) return;
    final acquired = await _coordinator._acquire(
      this,
      () => _visible && request == _generation,
    );
    if (!acquired) {
      if (!_closed && request == _generation && _visible) {
        _loading = false;
        _error = 'Previous playback resources could not be released';
        _notify();
      }
      return;
    }

    _PlayerSlot? target;
    await _enqueue(() async {
      if (_closed || request != _generation) return;
      final old = _active;
      if (old != null &&
          old.index == index &&
          old.failure == null &&
          !isLocked) {
        target = old;
        return;
      }
      if (old != null) await old.player.pause();
      final warm = _next;
      _active = null;
      _next = null;
      final hit = warm?.index == index && warm?.failure == null && !isLocked;
      if (hit) {
        target = _active = warm;
        _loading = !warm!.prepared;
        _notify();
        // Start a ready successor before awaiting slow disposal of the old one.
        if (warm.prepared) await _start(warm, request);
      }
      await _retire(old);
      if (!hit) await _retire(warm);
      if (_closed || request != _generation || isLocked) return;
      if (target == null) {
        target = _active = _create(index);
        _loading = true;
        _notify();
      }
    });
    final slot = target;
    if (slot == null) return;
    await slot.ready;
    if (_closed || request != _generation || _active != slot) return;
    await _enqueue(() => _start(slot, request));
    if (!_closed && request == _generation) _schedulePreload();
  }

  Future<void> _start(_PlayerSlot slot, int request) async {
    bool valid() => !_closed && request == _generation && _active == slot;
    if (!valid()) return;
    if (slot.failure != null) {
      _error = slot.failure.toString();
      _loading = false;
      _notify();
      return;
    }
    if (!slot.prepared) return;
    if (!slot.activated) {
      await activate?.call(episodes[slot.index], slot.player);
      if (!valid()) return;
      slot.activated = true;
    }
    _loading = false;
    _notify();
    await _applyPlayback(slot);
  }

  Future<void> _applyPlayback(_PlayerSlot slot) async {
    if (_closed || _active != slot || !slot.activated) return;
    final shouldPlay = _mayPlay && slot.index == _currentIndex && !isLocked;
    if (shouldPlay == slot.playing) return;
    if (shouldPlay) {
      await slot.player.play();
    } else {
      await slot.player.pause();
    }
    slot.playing = shouldPlay;
  }

  void _schedulePreload() {
    final request = _generation;
    final index = _nextIndex;
    _preloadTask = () async {
      _PlayerSlot? candidate;
      await _enqueue(() async {
        if (_closed || request != _generation) return;
        final allowed =
            index != null &&
            index >= 0 &&
            index < episodes.length &&
            index != _currentIndex &&
            canPlay(episodes[index]);
        if (!allowed || _next?.index != index) {
          final stale = _next;
          _next = null;
          await _retire(stale);
        }
        if (!_visible ||
            _overlayOpen ||
            request != _generation ||
            _active?.prepared != true ||
            !allowed) {
          return;
        }
        try {
          candidate = _next ??= _create(index);
        } catch (_) {
          // Optional allocation failure must not interrupt the playing item.
        }
      });
      final slot = candidate;
      if (slot == null) return;
      await slot.ready;
      if (_closed || _next != slot) return;
      if (slot.failure != null) {
        // Optional work fails silently. A later explicit selection retries.
        await _enqueue(() async {
          if (_next != slot) return;
          _next = null;
          await _retire(slot);
        });
      } else {
        _notify();
      }
    }();
  }

  void setAppResumed(bool value) {
    _appResumed = value;
    _syncPlayback();
  }

  void setRouteVisible(bool value) {
    _routeVisible = value;
    _syncPlayback();
  }

  void setOverlayOpen(bool value) {
    _overlayOpen = value;
    _syncPlayback();
  }

  void setUserWantsPlay(bool value) {
    _userWantsPlay = value;
    _syncPlayback();
    _notify();
  }

  void _syncPlayback() {
    if (_closed) return;
    if (_visible && _selected && active == null) {
      unawaited(select(_currentIndex, preloadIndex: _nextIndex));
      return;
    }
    final slot = _active;
    if (slot != null) unawaited(_enqueue(() => _applyPlayback(slot)));
    if (_visible && !_overlayOpen && !_loading) _schedulePreload();
  }

  Future<void> _releasePlayers() {
    _generation++;
    return _enqueue(() async {
      _active = _next = null;
      _loading = false;
      _notify();
      for (final slot in _live.toList()) {
        await _retire(slot);
      }
    });
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _releasePlayers();
    _coordinator._forget(this);
    super.dispose();
  }
}

class _PlayerSlot {
  _PlayerSlot(this.index, this.player);
  final int index;
  final PlayerPort player;
  late final Future<void> ready;
  bool prepared = false;
  bool activated = false;
  bool playing = false;
  bool retiring = false;
  Object? failure;
}
