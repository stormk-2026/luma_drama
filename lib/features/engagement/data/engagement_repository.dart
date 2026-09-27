import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engagement_snapshot.dart';

abstract interface class EngagementRepository {
  Future<EngagementSnapshot> load();
  Future<void> save(EngagementSnapshot snapshot);
}

class SharedPreferencesEngagementRepository implements EngagementRepository {
  SharedPreferencesEngagementRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'engagement.v1.demo-local-v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<EngagementSnapshot> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const EngagementSnapshot();
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return const EngagementSnapshot();
      Set<String> ids(Object? value) =>
          value is List ? value.whereType<String>().toSet() : <String>{};
      final comments = <String, List<String>>{};
      final rawComments = json['comments'];
      if (rawComments is Map<String, dynamic>) {
        for (final entry in rawComments.entries) {
          if (entry.value is List) {
            comments[entry.key] = (entry.value as List)
                .whereType<String>()
                .toList();
          }
        }
      }
      return EngagementSnapshot(
        savedDramaIds: ids(json['saved']),
        likedDramaIds: ids(json['liked']),
        commentsByDrama: comments,
      );
    } catch (_) {
      return const EngagementSnapshot();
    }
  }

  @override
  Future<void> save(EngagementSnapshot snapshot) => _preferences.setString(
    _key,
    jsonEncode({
      'saved': snapshot.savedDramaIds.toList(),
      'liked': snapshot.likedDramaIds.toList(),
      'comments': snapshot.commentsByDrama,
    }),
  );
}

class InMemoryEngagementRepository implements EngagementRepository {
  EngagementSnapshot snapshot = const EngagementSnapshot();

  @override
  Future<EngagementSnapshot> load() async => snapshot;

  @override
  Future<void> save(EngagementSnapshot value) async => snapshot = value;
}
