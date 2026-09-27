import 'package:flutter_test/flutter_test.dart';
import 'package:luma_drama/features/library/data/watch_history_repository.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('resume position clamps invalid and completed values', () {
    const duration = Duration(seconds: 8);
    expect(
      clampResumePosition(const Duration(seconds: -1), duration),
      Duration.zero,
    );
    expect(
      clampResumePosition(const Duration(seconds: 3), duration),
      const Duration(seconds: 3),
    );
    expect(
      clampResumePosition(const Duration(seconds: 9), duration),
      Duration.zero,
    );
    expect(
      clampResumePosition(const Duration(milliseconds: 7700), duration),
      Duration.zero,
    );
  });

  test('watch history is scoped by profile, drama and episode', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final history = SharedPreferencesWatchHistoryRepository();
    await history.save(
      'profile-a',
      'drama-a',
      'episode-1',
      const Duration(seconds: 3),
    );
    await history.save(
      'profile-a',
      'drama-a',
      'episode-2',
      const Duration(seconds: 5),
    );
    expect(
      await history.positionFor('profile-a', 'drama-a', 'episode-1'),
      const Duration(seconds: 3),
    );
    expect(
      await history.positionFor('profile-b', 'drama-a', 'episode-1'),
      isNull,
    );
    expect(await history.lastEpisodeId('profile-a', 'drama-a'), 'episode-2');
    expect(await history.lastEpisodeId('profile-a', 'drama-b'), isNull);
  });
}
