import 'package:flutter/foundation.dart';

import '../data/engagement_repository.dart';
import '../domain/engagement_snapshot.dart';

/// Local demo interactions, indexed by drama ID. No public/social backend.
class EngagementController extends ChangeNotifier {
  EngagementController(this._repository);

  final EngagementRepository _repository;
  final Set<String> _saved = {};
  final Set<String> _liked = {};
  final Map<String, List<String>> _comments = {};
  Future<void> _loadFuture = Future<void>.value();
  Future<void> _pendingSave = Future<void>.value();

  bool isSaved(String dramaId) => _saved.contains(dramaId);
  bool isLiked(String dramaId) => _liked.contains(dramaId);
  List<String> commentsFor(String dramaId) =>
      List.unmodifiable(_comments[dramaId] ?? const []);

  Future<void> load() => _loadFuture = _loadFromRepository();

  Future<void> _loadFromRepository() async {
    try {
      final snapshot = await _repository.load();
      _saved.addAll(snapshot.savedDramaIds);
      _liked.addAll(snapshot.likedDramaIds);
      for (final entry in snapshot.commentsByDrama.entries) {
        _comments[entry.key] = List.of(entry.value);
      }
      notifyListeners();
    } catch (_) {
      // Local preferences are best effort for this demo.
    }
  }

  Future<void> toggleSaved(String dramaId) async {
    await _loadFuture;
    if (!_saved.add(dramaId)) _saved.remove(dramaId);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleLiked(String dramaId) async {
    await _loadFuture;
    if (!_liked.add(dramaId)) _liked.remove(dramaId);
    notifyListeners();
    await _persist();
  }

  Future<void> addComment(String dramaId, String text) async {
    await _loadFuture;
    final clean = text.trim();
    if (clean.isEmpty) return;
    (_comments[dramaId] ??= []).add(
      clean.length > 300 ? clean.substring(0, 300) : clean,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() {
    final snapshot = EngagementSnapshot(
      savedDramaIds: Set.of(_saved),
      likedDramaIds: Set.of(_liked),
      commentsByDrama: {
        for (final entry in _comments.entries) entry.key: List.of(entry.value),
      },
    );
    _pendingSave = _pendingSave
        .then((_) => _repository.save(snapshot))
        .catchError((Object _) {
          // Keep the current in-memory state if local persistence fails.
        });
    return _pendingSave;
  }
}
