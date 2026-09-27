import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/locale_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/drama.dart';

/// Shortcuts for the existing root tabs; this widget owns no navigation state.
class HomeQuickDrawer extends StatelessWidget {
  const HomeQuickDrawer({
    super.key,
    required this.drama,
    required this.onOpenSeries,
    required this.onDiscover,
    required this.onHistory,
    required this.onWatchlist,
    required this.onLiked,
  });

  final Drama drama;
  final VoidCallback onOpenSeries;
  final VoidCallback onDiscover;
  final VoidCallback onHistory;
  final VoidCallback onWatchlist;
  final VoidCallback onLiked;

  static const _panel = Color(0xFF222225);
  static const _card = Color(0xFF303033);
  static const _orange = Color(0xFFFF5C37);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Drawer(
      width: (MediaQuery.sizeOf(context).width * 0.83).clamp(0.0, 360.0),
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF4B4142),
                  child: Icon(
                    Icons.person_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.localViewer,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.localDemoProfile,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _SectionCard(
              title: l10n.currentSeries,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          drama.posterAsset,
                          width: 74,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              drama.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              l10n.episodeCount(drama.episodes.length),
                              style: const TextStyle(color: Colors.white60),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              l10n.freeTestMedia,
                              maxLines: 2,
                              style: const TextStyle(
                                color: Color(0xFFFFB99E),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('drawer-open-series'),
                      onPressed: onOpenSeries,
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.exploreSeries),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: l10n.quickAccess,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          key: const Key('drawer-discover'),
                          icon: Icons.explore_outlined,
                          label: l10n.discoverTab,
                          onTap: onDiscover,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _QuickAction(
                          key: const Key('drawer-history'),
                          icon: Icons.history_rounded,
                          label: l10n.history,
                          onTap: onHistory,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          key: const Key('drawer-watchlist'),
                          icon: Icons.bookmark_border_rounded,
                          label: l10n.watchlist,
                          onTap: onWatchlist,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _QuickAction(
                          key: const Key('drawer-liked'),
                          icon: Icons.favorite_border_rounded,
                          label: l10n.likedTab,
                          onTap: onLiked,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: l10n.appLanguage,
              child: Row(
                children: [
                  for (final (code, label) in [
                    ('en', l10n.english),
                    ('zh', l10n.simplifiedChinese),
                  ]) ...[
                    Expanded(
                      child: ChoiceChip(
                        label: Text(label, maxLines: 1),
                        selected: languageCode == code,
                        onSelected: (_) =>
                            context.read<LocaleController>().select(code),
                      ),
                    ),
                    if (code == 'en') const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: HomeQuickDrawer._card,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF3B3B3F),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
        child: Column(
          children: [
            Icon(icon, color: HomeQuickDrawer._orange, size: 25),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}
