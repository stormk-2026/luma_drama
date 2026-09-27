import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../library/data/watch_history_repository.dart';
import '../domain/drama.dart';

enum DiscoverPageAction { home, my, watchlist, detail, resume }

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({
    super.key,
    required this.drama,
    required this.duration,
    this.focusSearch = false,
    this.history,
    this.embedded = false,
    this.active = true,
    this.searchRequest = 0,
    this.onAction,
    this.dramas,
    this.onDramaSelected,
  });

  final Drama drama;
  final Duration duration;
  final bool focusSearch;
  final WatchHistoryRepository? history;
  final bool embedded;
  final bool active;
  final int searchRequest;
  final ValueChanged<DiscoverPageAction>? onAction;
  final List<Drama>? dramas;
  final ValueChanged<Drama>? onDramaSelected;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late final WatchHistoryRepository _history =
      widget.history ?? SharedPreferencesWatchHistoryRepository();
  late Future<Duration?> _position;
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scroll = ScrollController();
  int _category = 0;

  @override
  void initState() {
    super.initState();
    _refreshPosition();
  }

  void _refreshPosition() {
    _position = _history.positionFor(
      demoProfileId,
      widget.drama.id,
      widget.drama.episodes.first.id,
    );
  }

  @override
  void didUpdateWidget(covariant DiscoverPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        (!oldWidget.active || oldWidget.drama.id != widget.drama.id)) {
      setState(_refreshPosition);
    }
    if (widget.active && widget.searchRequest != oldWidget.searchRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active) _searchFocus.requestFocus();
      });
    }
  }

  void _act(DiscoverPageAction action) {
    if (widget.embedded) {
      widget.onAction?.call(action);
    } else {
      Navigator.pop(context, action);
    }
  }

  Drama? _dramaFor(_ShowcaseCard card) {
    for (final drama in widget.dramas ?? [widget.drama]) {
      if (drama.id == card.dramaId) return drama;
    }
    return null;
  }

  void _openCard(_ShowcaseCard card) {
    final drama = _dramaFor(card);
    if (drama == null) {
      _unavailable();
    } else if (widget.embedded && widget.onDramaSelected != null) {
      widget.onDramaSelected!(drama);
    } else {
      _act(DiscoverPageAction.detail);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _unavailable() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.artworkOnlyNotice)));
  }

  void _catalogInfo() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.demoCatalogNotice)));
  }

  void _showFilters() {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.featured,
      l10n.suspense,
      l10n.romance,
      l10n.actionGenre,
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF202126),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.filter)),
            for (var index = 0; index < labels.length; index++)
              ListTile(
                title: Text(labels[index]),
                trailing: index == _category
                    ? const Icon(Icons.check_rounded, color: _orange)
                    : null,
                onTap: () {
                  setState(() => _category = index);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = _cardsFor(_category, _search.text);
    final content = SafeArea(
      bottom: !widget.embedded,
      child: Column(
        children: [
          _topBar(l10n),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _searchBar(l10n),
                const SizedBox(height: 12),
                _categories(l10n),
                const SizedBox(height: 15),
                _continueCard(l10n),
                const SizedBox(height: 15),
                _quickActions(l10n),
                const SizedBox(height: 20),
                _sectionTitle(l10n),
                const SizedBox(height: 13),
                if (cards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.noSearchResults,
                      style: const TextStyle(color: Color(0xFFAAAAB0)),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.59,
                        ),
                    itemBuilder: (context, index) =>
                        _posterCard(l10n, cards[index]),
                  ),
              ],
            ),
          ),
          if (!widget.embedded) _bottomNav(l10n),
        ],
      ),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: widget.embedded
            ? content
            : Scaffold(backgroundColor: const Color(0xFF0B0C10), body: content),
      ),
    );
  }

  Widget _topBar(AppLocalizations l10n) => SizedBox(
    height: 51,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
          const SizedBox(width: 7),
          Text(
            l10n.discoverTab,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          IconButton(
            tooltip: l10n.search,
            onPressed: () => _searchFocus.requestFocus(),
            icon: const Icon(Icons.search_rounded, size: 22),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _act(DiscoverPageAction.my),
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF34353B),
              child: Icon(Icons.person_rounded, size: 19),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _searchBar(AppLocalizations l10n) => Container(
    height: 43,
    decoration: BoxDecoration(
      color: const Color(0xFF25252A),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        const SizedBox(width: 11),
        const Icon(Icons.search_rounded, color: Color(0xFFB8AFB3), size: 20),
        const SizedBox(width: 7),
        Expanded(
          child: TextField(
            controller: _search,
            focusNode: _searchFocus,
            autofocus: widget.focusSearch,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: l10n.searchDiscover,
              hintStyle: const TextStyle(
                color: Color(0xFFABA3A8),
                fontSize: 11,
              ),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.filter,
          onPressed: _showFilters,
          icon: const Icon(Icons.tune_rounded, size: 20),
        ),
      ],
    ),
  );

  Widget _categories(AppLocalizations l10n) {
    final labels = [
      l10n.featured,
      l10n.suspense,
      l10n.romance,
      l10n.actionGenre,
    ];
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) => ChoiceChip(
          label: Text(labels[index]),
          selected: _category == index,
          onSelected: (_) => setState(() => _category = index),
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          backgroundColor: const Color(0xFF29272B),
          selectedColor: _orange,
          side: BorderSide.none,
          labelStyle: TextStyle(
            color: _category == index ? Colors.white : const Color(0xFFDDD5D7),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _continueCard(AppLocalizations l10n) => FutureBuilder<Duration?>(
    future: _position,
    builder: (context, snapshot) {
      final position = snapshot.data ?? Duration.zero;
      final total = widget.duration > Duration.zero
          ? widget.duration
          : const Duration(seconds: 12);
      final progress = (position.inMilliseconds / total.inMilliseconds).clamp(
        0.0,
        1.0,
      );
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1D21),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                width: 55,
                height: 69,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(widget.drama.posterAsset, fit: BoxFit.cover),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 12,
                      child: ColoredBox(color: Color(0xFF1C1D21)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.continueWatching.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFA490),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.drama.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.episodeProgress(1, widget.drama.episodes.length),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFAAA4A7),
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: const Color(0xFF474248),
                      color: _orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            FilledButton.icon(
              onPressed: () => _act(DiscoverPageAction.resume),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFBD5C),
                foregroundColor: const Color(0xFF2A160B),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 14),
              label: Text(l10n.resume),
            ),
          ],
        ),
      );
    },
  );

  Widget _quickActions(AppLocalizations l10n) {
    final actions = [
      (Icons.tune_rounded, l10n.filter, _showFilters),
      (Icons.bar_chart_rounded, l10n.topCharts, _catalogInfo),
      (Icons.auto_awesome_rounded, l10n.newReleases, _catalogInfo),
      (
        Icons.bookmark_outline_rounded,
        l10n.watchlist,
        () {
          _act(DiscoverPageAction.watchlist);
        },
      ),
    ];
    return Row(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          Expanded(
            child: InkWell(
              onTap: actions[index].$3,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 77,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF202126),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF333036),
                      child: Icon(
                        actions[index].$1,
                        size: 19,
                        color: index == 1
                            ? const Color(0xFFFFC15E)
                            : const Color(0xFFFFAB96),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      actions[index].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (index < actions.length - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }

  Widget _sectionTitle(AppLocalizations l10n) => Row(
    children: [
      Container(width: 3, height: 20, color: _orange),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          l10n.trendingMicroDramas,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      TextButton(
        onPressed: () => setState(() => _category = 0),
        child: Text(
          l10n.seeAll,
          style: const TextStyle(color: Color(0xFFFFB3A1)),
        ),
      ),
    ],
  );

  Widget _posterCard(AppLocalizations l10n, _ShowcaseCard card) {
    final playable = _dramaFor(card) != null;
    return InkWell(
      onTap: () => _openCard(card),
      borderRadius: BorderRadius.circular(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(card.image, fit: BoxFit.cover),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 37,
                    child: ColoredBox(color: Color(0xFF101116)),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: playable ? _orange : const Color(0xDD37343B),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        playable ? l10n.free : l10n.artworkOnly,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 8,
                    right: 8,
                    child: Text(
                      playable ? l10n.freeTestMedia : l10n.videoPending,
                      style: const TextStyle(
                        color: Color(0xFFFFC789),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            card.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            card.genre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFB9AFB2), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav(AppLocalizations l10n) => Container(
    height: 63,
    decoration: const BoxDecoration(
      color: Color(0xFF0D0D11),
      border: Border(top: BorderSide(color: Color(0xFF242329))),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _DiscoverNavItem(
          icon: Icons.play_circle_outline_rounded,
          label: l10n.homeTab,
          onTap: () => Navigator.pop(context, DiscoverPageAction.home),
        ),
        _DiscoverNavItem(
          icon: Icons.explore_outlined,
          label: l10n.discoverTab,
          selected: true,
          onTap: () {},
        ),
        _DiscoverNavItem(
          icon: Icons.video_library_outlined,
          label: l10n.myTab,
          onTap: () => Navigator.pop(context, DiscoverPageAction.my),
        ),
      ],
    ),
  );
}

class _DiscoverNavItem extends StatelessWidget {
  const _DiscoverNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 21,
            color: selected ? _orange : const Color(0xFFCAC4C7),
          ),
          Text(
            label,
            style: TextStyle(
              color: selected ? _orange : const Color(0xFFCAC4C7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ShowcaseCard {
  const _ShowcaseCard({
    required this.title,
    required this.genre,
    required this.image,
    required this.category,
    this.dramaId,
  });

  final String title;
  final String genre;
  final String image;
  final int category;
  final String? dramaId;
}

List<_ShowcaseCard> _cardsFor(int category, String query) {
  const cards = [
    _ShowcaseCard(
      title: 'The Signal',
      genre: 'Suspense · Mystery',
      image: 'assets/images/stitch_signal_poster_clean.png',
      category: 1,
      dramaId: 'the-signal-demo',
    ),
    _ShowcaseCard(
      title: 'City Lights & Velvet Nights',
      genre: 'Urban Romance',
      image: 'assets/images/stitch_city_poster_clean.png',
      category: 2,
      dramaId: 'city-lights-demo',
    ),
    _ShowcaseCard(
      title: 'Vengeance Rising',
      genre: 'Action · Thriller',
      image: 'assets/images/stitch_vengeance_poster_clean.png',
      category: 3,
      dramaId: 'vengeance-demo',
    ),
    _ShowcaseCard(
      title: 'Echoes of Fate',
      genre: 'Drama · Mystery',
      image: 'assets/images/stitch_rain_scene.jpg',
      category: 1,
    ),
  ];
  final normalized = query.trim().toLowerCase();
  return cards.where((card) {
    final categoryMatches = category == 0 || card.category == category;
    final queryMatches =
        normalized.isEmpty ||
        card.title.toLowerCase().contains(normalized) ||
        card.genre.toLowerCase().contains(normalized);
    return categoryMatches && queryMatches;
  }).toList();
}

const _orange = Color(0xFFFF5B3D);
