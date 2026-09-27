import '../l10n/app_localizations.dart';

String localizedEpisodeTitle(AppLocalizations l10n, int number) =>
    switch (number) {
      1 => l10n.episodeOneTitle,
      2 => l10n.episodeTwoTitle,
      3 => l10n.episodeThreeTitle,
      4 => l10n.episodeFourTitle,
      _ => 'Episode $number',
    };
