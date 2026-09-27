import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/drama.dart';
import '../../library/data/watch_history_repository.dart';
import '../../playback/presentation/player_page.dart';

class DramaDetailPage extends StatefulWidget {
  const DramaDetailPage({super.key, required this.drama});
  final Drama drama;

  @override
  State<DramaDetailPage> createState() => _DramaDetailPageState();
}

class _DramaDetailPageState extends State<DramaDetailPage> {
  final WatchHistoryRepository _history =
      SharedPreferencesWatchHistoryRepository();
  int? _continueIndex;
  Drama get drama => widget.drama;

  @override
  void initState() {
    super.initState();
    _loadContinue();
  }

  Future<void> _loadContinue() async {
    try {
      final id = await _history.lastEpisodeId(demoProfileId, drama.id);
      if (!mounted || id == null) return;
      final index = drama.episodes.indexWhere((episode) => episode.id == id);
      if (index >= 0 && drama.episodes[index].isFree) {
        setState(() => _continueIndex = index);
      }
    } catch (_) {
      // Keep the first episode available if preferences cannot be read.
    }
  }

  Future<void> _openPlayer(BuildContext context, int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerPage(drama: drama, initialIndex: index),
      ),
    );
    await _loadContinue();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF111111),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(drama.posterAsset, fit: BoxFit.cover),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  l10n.technicalDemoCount(drama.episodes.length),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.4,
                    color: const Color(0xFF9278EA),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  drama.title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  drama.synopsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openPlayer(context, _continueIndex ?? 0),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    _continueIndex == null
                        ? l10n.watchEpisodeOne
                        : l10n.continueEpisode(_continueIndex! + 1),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  l10n.episodes,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            sliver: SliverList.builder(
              itemCount: drama.episodes.length,
              itemBuilder: (context, index) {
                final episode = drama.episodes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    minTileHeight: 76,
                    leading: CircleAvatar(
                      backgroundColor: const Color(
                        0xFFFF6B45,
                      ).withValues(alpha: 0.18),
                      child: Text('${episode.number}'),
                    ),
                    title: Text(l10n.episodeLabel(episode.number)),
                    subtitle: Text(l10n.freeTestMedia),
                    trailing: const Icon(Icons.play_circle_outline_rounded),
                    onTap: () => _openPlayer(context, index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
