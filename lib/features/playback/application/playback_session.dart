import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../catalog/domain/drama.dart';
import '../domain/player_port.dart';

typedef PlayerFactory = PlayerPort Function(Episode episode);

/// Owns the only live player. Allocation and disposal are serialized.
class PlaybackSession extends ChangeNotifier {
  PlaybackSession({
    required this.episodes,
    required this.factory,
    required this.canPlay,
    this.prepare,
  });

  final List<Episode> episodes;
  final PlayerFactory factory;
  final bool Function(Episode) canPlay;
  final Future<void> Function(Episode episode, PlayerPort player)? prepare;

  PlayerPort? _active;
  Future<void> _transition = Future<void>.value();
  Future<void> _playbackOperation = Future<void>.value();
  int _generation = 0;
  int _currentIndex = 0;
  bool _loading = false;
  bool _closed = false;
  bool _appResumed = true;
  bool _routeVisible = true;
  bool _overlayOpen = false;
  bool _userWantsPlay = true;
  String? _error;

  int get currentIndex => _currentIndex;
  Episode get currentEpisode => episodes[_currentIndex];
  PlayerPort? get active => _active;
  bool get loading => _loading;
  bool get userWantsPlay => _userWantsPlay;
  bool get canAutoAdvance =>
      !_closed &&
      _appResumed &&
      _routeVisible &&
      !_overlayOpen &&
      _userWantsPlay &&
      !_loading;
  bool get isLocked => !canPlay(currentEpisode);
  String? get error => _error;
  int get livePlayerCount => _active == null ? 0 : 1;
  Future<void> get playbackSettled => _playbackOperation;

  Future<void> select(int index) async {
    if (_closed || index < 0 || index >= episodes.length) return;
    final request = ++_generation;
    _currentIndex = index;
    _error = null;
    _loading = false;
    _notify();

    PlayerPort? next;
    final transition = _transition.then((_) async {
      final old = _active;
      _active = null;
      await _playbackOperation;
      if (old != null) {
        try {
          await old.pause();
        } finally {
          await old.dispose();
        }
      }
      if (_closed || request != _generation || !canPlay(episodes[index])) {
        return;
      }
      next = factory(episodes[index]);
      _active = next;
      _loading = true;
      _notify();
    });
    _transition = transition;
    await transition;
    final player = next;
    if (player == null) return;

    try {
      await player.initialize();
      if (_closed || request != _generation || _active != player) return;
      await prepare?.call(episodes[index], player);
      if (_closed || request != _generation || _active != player) return;
      _loading = false;
      _syncPlayback();
      _notify();
      await _playbackOperation;
    } catch (error) {
      if (_closed || request != _generation || _active != player) return;
      _loading = false;
      _error = error.toString();
      _notify();
    }
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
    final player = _active;
    if (player == null || _loading || _closed) return;
    _playbackOperation = _playbackOperation
        .then((_) async {
          if (_active != player || _closed) return;
          if (_appResumed &&
              _routeVisible &&
              !_overlayOpen &&
              _userWantsPlay &&
              !isLocked) {
            await player.play();
          } else {
            await player.pause();
          }
        })
        .catchError((Object _) {
          if (!_closed && _active == player) {
            _error = 'Playback control failed';
            _notify();
          }
        });
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _generation++;
    await _transition;
    await _playbackOperation;
    final player = _active;
    _active = null;
    if (player != null) {
      try {
        await player.pause();
      } finally {
        await player.dispose();
      }
    }
    super.dispose();
  }
}
