import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/presentation/catalog_controller.dart';
import '../features/catalog/presentation/home_page.dart';
import '../features/engagement/application/engagement_controller.dart';
import '../features/engagement/data/engagement_repository.dart';
import '../l10n/app_localizations.dart';
import 'locale_controller.dart';

class LumaDramaApp extends StatelessWidget {
  const LumaDramaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CatalogController(DemoCatalogRepository())..load(),
        ),
        ChangeNotifierProvider(create: (_) => LocaleController()..load()),
        ChangeNotifierProvider(
          create: (_) =>
              EngagementController(SharedPreferencesEngagementRepository())
                ..load(),
        ),
      ],
      child: Consumer<LocaleController>(
        builder: (context, locale, _) => MaterialApp(
          title: 'LumaDrama',
          locale: locale.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6D4AFF),
            ),
            scaffoldBackgroundColor: const Color(0xFFF8F7FC),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF9B86FF),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF101019),
          ),
          home: const HomePage(),
        ),
      ),
    );
  }
}
