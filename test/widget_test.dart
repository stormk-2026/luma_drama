import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_drama/app/luma_drama_app.dart';
import 'package:luma_drama/features/playback/presentation/player_page.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/widget_player.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
    'home swipe promotes next without recreating it or showing loading',
    (tester) async {
      final created = <String>[];
      await tester.pumpWidget(
        LumaDramaApp(
          playerFactory: (episode) {
            created.add(episode.id);
            return WidgetPlayer();
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(created, hasLength(2));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.drag(find.byType(PageView), const Offset(0, -550));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('City Lights & Velvet Nights'), findsOneWidget);
      expect(created, hasLength(3));
      expect(created.toSet(), hasLength(3));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('immersive home opens the series detail', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LumaDramaApp(playerFactory: createWidgetPlayer),
    );
    await tester.pumpAndSettle();
    expect(find.text('The Signal'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.textContaining('Playing now'), findsOneWidget);
    expect(find.byTooltip('Episodes'), findsWidgets);
    expect(find.byTooltip('Watch in landscape'), findsOneWidget);
    expect(find.byTooltip('Picture in picture'), findsOneWidget);

    await tester.tap(find.byTooltip('Explore series'));
    await tester.pumpAndSettle();
    expect(find.text('Watch episode 1'), findsOneWidget);
    expect(find.text('Episodes'), findsOneWidget);
  });

  testWidgets('landscape control hides tabs and restores them on exit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LumaDramaApp(playerFactory: createWidgetPlayer),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Watch in landscape'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-tabs-bar')), findsNothing);
    expect(find.byTooltip('Exit fullscreen'), findsOneWidget);
    await tester.tap(find.byTooltip('Exit fullscreen'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-tabs-bar')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home quick drawer opens current series and switches root tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LumaDramaApp(playerFactory: createWidgetPlayer),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open quick menu'));
    await tester.pumpAndSettle();
    expect(tester.widget<PlayerPage>(find.byType(PlayerPage)).active, isFalse);
    expect(find.text('Quick access'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Same demo clip · free'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('drawer-open-series')));
    await tester.pumpAndSettle();
    expect(find.text('Watch episode 1'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.widget<PlayerPage>(find.byType(PlayerPage)).active, isTrue);

    await tester.tap(find.byTooltip('Open quick menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawer-discover')));
    await tester.pumpAndSettle();
    expect(find.text('Trending Micro-Dramas'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.text('Trending Micro-Dramas'))).canPop(),
      isFalse,
    );
  });

  testWidgets('interface language changes without a caption control', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LumaDramaApp(playerFactory: createWidgetPlayer),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Captions'), findsNothing);
    await tester.tap(find.byTooltip('My'));
    await tester.pumpAndSettle();
    expect(find.text('Continue Watching'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('App Language'),
      120,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('PREFERENCES'), findsOneWidget);
    await tester.tap(find.text('App Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('简体中文').last);
    await tester.pumpAndSettle();
    expect(find.text('我的'), findsWidgets);
    expect(find.text('继续观看'), findsOneWidget);
    expect(find.text('找剧'), findsOneWidget);
    await tester.tap(find.text('找剧'));
    await tester.pumpAndSettle();
    expect(find.text('热门短剧'), findsOneWidget);
    expect(find.text('排行榜'), findsOneWidget);
  });

  testWidgets('home controls fit a compact Android viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LumaDramaApp(playerFactory: createWidgetPlayer),
    );
    await tester.pumpAndSettle();
    expect(find.text('Recommended'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('City Lights & Velvet Nights'), findsOneWidget);
    await tester.tap(find.byTooltip('Explore series'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch episode 1'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My page fits a compact Android viewport and returns home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LumaDramaApp(playerFactory: createWidgetPlayer),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('My'));
    await tester.pumpAndSettle();
    expect(find.text('Continue Watching'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Recommended'), findsOneWidget);
  });

  testWidgets(
    'Discover shows three mock playable dramas and one pending poster',
    (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const LumaDramaApp(playerFactory: createWidgetPlayer),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();

      expect(find.text('Trending Micro-Dramas'), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Top Charts'), findsOneWidget);
      expect(find.text('New Releases'), findsOneWidget);
      expect(find.text('Watchlist'), findsOneWidget);
      expect(find.text('Same demo clip · free'), findsNWidgets(3));
      expect(find.text('Video pending'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), 'Vengeance');
      await tester.pumpAndSettle();
      expect(find.text('Vengeance Rising'), findsOneWidget);
      expect(find.text('Same demo clip · free'), findsOneWidget);

      await tester.tap(find.text('Watchlist'));
      await tester.pumpAndSettle();
      expect(find.text('No shows here yet.'), findsOneWidget);
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(find.text('Recommended'), findsOneWidget);
    },
  );

  testWidgets('bottom tabs stay on one route and preserve Discover search', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LumaDramaApp(playerFactory: createWidgetPlayer),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Vengeance');
    await tester.pumpAndSettle();
    expect(find.text('Vengeance Rising'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(TextField))).canPop(),
      isFalse,
    );

    await tester.tap(find.byKey(const Key('tab-my')));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.text('History'))).canPop(),
      isFalse,
    );
    await tester.tap(find.text('Watchlist'));
    await tester.pumpAndSettle();
    expect(find.text('No shows here yet.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tab-discover')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Vengeance'), findsOneWidget);
    expect(find.text('Vengeance Rising'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(TextField))).canPop(),
      isFalse,
    );
    await tester.tap(find.byKey(const Key('tab-my')));
    await tester.pumpAndSettle();
    expect(find.text('No shows here yet.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-home')));
    await tester.pumpAndSettle();
    expect(find.text('Recommended'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.text('Recommended'))).canPop(),
      isFalse,
    );
  });

  testWidgets(
    'home swipe changes drama, entered player swipe changes episode',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const LumaDramaApp(playerFactory: createWidgetPlayer),
      );
      await tester.pumpAndSettle();
      expect(find.text('The Signal'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(0, -550));
      await tester.pumpAndSettle();
      expect(find.text('City Lights & Velvet Nights'), findsOneWidget);
      expect(find.textContaining('Episode 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Explore series'));
      await tester.pumpAndSettle();
      expect(find.text('City Lights & Velvet Nights'), findsOneWidget);
      await tester.tap(find.text('Watch episode 1'));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(0, -550));
      await tester.pumpAndSettle();
      expect(find.textContaining('EPISODE 2 / 3'), findsOneWidget);
      expect(find.text('City Lights & Velvet Nights'), findsWidgets);
    },
  );

  testWidgets('home categories switch by video, top row and tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LumaDramaApp(playerFactory: createWidgetPlayer),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.tune_rounded), findsNothing);
    expect(find.text('The Signal'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('home-video-swipe')),
      const Offset(220, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('City Lights & Velvet Nights'), findsOneWidget);
    expect(find.byKey(const Key('home-category-liveAction')), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(0, -550));
    await tester.pumpAndSettle();
    expect(find.text('Vengeance Rising'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('home-category-swipe')),
      const Offset(190, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('The Signal'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('home-category-swipe')),
      const Offset(-190, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('City Lights & Velvet Nights'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-category-following')));
    await tester.pumpAndSettle();
    expect(find.text('No dramas in this category yet.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-category-recommended')));
    await tester.pumpAndSettle();
    expect(find.text('The Signal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('right rail saves, comments, likes and invokes share in order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? sharedText;
    const channel = MethodChannel('com.stormg.lumadrama/share');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      sharedText = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    await tester.pumpWidget(
      const LumaDramaApp(playerFactory: createWidgetPlayer),
    );
    await tester.pumpAndSettle();
    final keys = [
      const Key('rail-save'),
      const Key('rail-comments'),
      const Key('rail-like'),
      const Key('rail-share'),
    ];
    final tops = keys
        .map((key) => tester.getTopLeft(find.byKey(key)).dy)
        .toList();
    expect(tops, orderedEquals(tops.toList()..sort()));

    await tester.tap(find.byKey(keys[0]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(keys[1]));
    await tester.pumpAndSettle();
    expect(find.text('Only visible on this device'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('comment-input')), 'Nice demo');
    await tester.tap(find.byKey(const Key('comment-post')));
    await tester.pumpAndSettle();
    expect(find.text('Nice demo'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(keys[2]));
    await tester.tap(find.byKey(keys[3]));
    await tester.pumpAndSettle();
    expect(sharedText, contains('The Signal'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'right swipe from leftmost category opens drawer and root stays',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const LumaDramaApp(playerFactory: createWidgetPlayer),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.drag(
          find.byKey(const Key('home-category-swipe')),
          const Offset(200, 0),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('No dramas in this category yet.'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('home-empty-swipe')),
        const Offset(200, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Quick access'), findsOneWidget);
      await tester.drag(find.byType(Drawer), const Offset(150, 0));
      await tester.pumpAndSettle();
      expect(find.text('Quick access'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-tabs-bar')), findsOneWidget);
    },
  );

  testWidgets('system back steps categories then opens drawer without exit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const LumaDramaApp(playerFactory: createWidgetPlayer),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('City Lights & Velvet Nights'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('The Signal'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('No dramas in this category yet.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Quick access'), findsOneWidget);
    expect(find.byKey(const Key('home-tabs-bar')), findsOneWidget);
  });

  testWidgets('My watchlist lists saved dramas across the home feed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const LumaDramaApp(playerFactory: createWidgetPlayer),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('rail-save')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(0, -550));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rail-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-my')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watchlist'));
    await tester.pumpAndSettle();
    expect(find.text('The Signal'), findsOneWidget);
    expect(find.text('City Lights & Velvet Nights'), findsWidgets);
    await tester.tap(find.text('The Signal'));
    await tester.pumpAndSettle();
    expect(find.text('Watch episode 1'), findsOneWidget);
  });
}
