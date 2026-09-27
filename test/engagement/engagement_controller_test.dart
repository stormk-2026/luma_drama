import 'package:flutter_test/flutter_test.dart';
import 'package:luma_drama/features/engagement/application/engagement_controller.dart';
import 'package:luma_drama/features/engagement/data/engagement_repository.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('saved, liked and comments are kept by drama id', () async {
    final repository = InMemoryEngagementRepository();
    final first = EngagementController(repository);
    await first.load();
    await first.toggleSaved('signal');
    await first.toggleLiked('signal');
    await first.addComment('signal', '  Great clip  ');

    expect(first.isSaved('signal'), isTrue);
    expect(first.isSaved('city'), isFalse);
    expect(first.isLiked('city'), isFalse);
    expect(first.commentsFor('signal'), ['Great clip']);
    expect(first.commentsFor('city'), isEmpty);

    final reopened = EngagementController(repository);
    await reopened.load();
    expect(reopened.isSaved('signal'), isTrue);
    expect(reopened.isLiked('signal'), isTrue);
    expect(reopened.commentsFor('signal'), ['Great clip']);
    await reopened.toggleSaved('signal');
    expect(reopened.isSaved('signal'), isFalse);
  });

  test('local engagement survives a new repository instance', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final first = EngagementController(SharedPreferencesEngagementRepository());
    await first.load();
    await first.toggleSaved('city');
    await first.addComment('city', 'Local note');

    final reopened = EngagementController(
      SharedPreferencesEngagementRepository(),
    );
    await reopened.load();
    expect(reopened.isSaved('city'), isTrue);
    expect(reopened.commentsFor('city'), ['Local note']);
  });
}
