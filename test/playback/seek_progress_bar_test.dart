import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_drama/features/playback/presentation/seek_progress_bar.dart';
import 'package:video_player/video_player.dart';

void main() {
  test('seek target stays inside playable duration', () {
    const duration = Duration(seconds: 12);
    expect(seekPositionForFraction(0, duration), Duration.zero);
    expect(
      seekPositionForFraction(0.5, duration),
      greaterThan(const Duration(seconds: 5)),
    );
    expect(seekPositionForFraction(1, duration), lessThan(duration));
  });

  testWidgets('horizontal slider drag previews and seeks on release', (
    tester,
  ) async {
    final video = ValueNotifier<VideoPlayerValue>(
      const VideoPlayerValue(
        duration: Duration(seconds: 12),
        position: Duration(seconds: 3),
        isInitialized: true,
      ),
    );
    addTearDown(video.dispose);
    var started = 0;
    Duration? target;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SeekProgressBar(
                valueListenable: video,
                semanticsLabel: 'Seek video',
                onScrubStart: () => started++,
                onSeek: (position) async {
                  target = position;
                },
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Slider)),
    );
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();
    expect(started, 1);
    expect(target, isNull);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(target, isNotNull);
    expect(target!, greaterThan(const Duration(seconds: 3)));
    expect(target!, lessThan(const Duration(seconds: 12)));
  });

  testWidgets('compact seek bar shows time only while dragging', (
    tester,
  ) async {
    final video = ValueNotifier<VideoPlayerValue>(
      const VideoPlayerValue(
        duration: Duration(seconds: 12),
        position: Duration(seconds: 3),
        isInitialized: true,
      ),
    );
    addTearDown(video.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeekProgressBar(
            valueListenable: video,
            semanticsLabel: 'Seek video',
            compactIdle: true,
            onSeek: (_) async {},
          ),
        ),
      ),
    );
    expect(find.text('00:03'), findsNothing);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Slider)),
    );
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(find.text('00:12'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('00:12'), findsNothing);
  });
}
