import 'package:shared_preferences/shared_preferences.dart';

const demoProfileId = 'demo-local-v1';

abstract interface class WatchHistoryRepository {
  Future<Duration?> positionFor(
    String profileId,
    String dramaId,
    String episodeId,
  );
  Future<String?> lastEpisodeId(String profileId, String dramaId);
  Future<void> save(
    String profileId,
    String dramaId,
    String episodeId,
    Duration position,
  );
}

class SharedPreferencesWatchHistoryRepository
    implements WatchHistoryRepository {
  SharedPreferencesWatchHistoryRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  String _positionKey(String profile, String drama, String episode) =>
      'watch.v1.$profile.$drama.$episode.positionMs';
  String _lastKey(String profile, String drama) =>
      'watch.v1.$profile.$drama.lastEpisode';

  @override
  Future<Duration?> positionFor(
    String profileId,
    String dramaId,
    String episodeId,
  ) async {
    final milliseconds = await _preferences.getInt(
      _positionKey(profileId, dramaId, episodeId),
    );
    return milliseconds == null ? null : Duration(milliseconds: milliseconds);
  }

  @override
  Future<String?> lastEpisodeId(String profileId, String dramaId) =>
      _preferences.getString(_lastKey(profileId, dramaId));

  @override
  Future<void> save(
    String profileId,
    String dramaId,
    String episodeId,
    Duration position,
  ) async {
    await _preferences.setInt(
      _positionKey(profileId, dramaId, episodeId),
      position.inMilliseconds,
    );
    await _preferences.setString(_lastKey(profileId, dramaId), episodeId);
  }
}

Duration clampResumePosition(Duration saved, Duration duration) {
  if (duration <= const Duration(milliseconds: 500)) return Duration.zero;
  if (saved <= Duration.zero) return Duration.zero;
  final lastUsefulPosition = duration - const Duration(milliseconds: 500);
  if (saved >= lastUsefulPosition) return Duration.zero;
  return saved;
}
