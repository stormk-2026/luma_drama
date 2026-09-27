import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/locale_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/domain/drama.dart';
import '../../engagement/application/engagement_controller.dart';
import '../data/watch_history_repository.dart';

enum MyPageAction { home, discover, resume }

class MyPage extends StatefulWidget {
  const MyPage({
    super.key,
    required this.drama,
    required this.duration,
    this.initialSection = 0,
    this.history,
    this.embedded = false,
    this.active = true,
    this.sectionRequest = 0,
    this.onAction,
    this.dramas,
    this.onDramaSelected,
  });

  final Drama drama;
  final Duration duration;
  final int initialSection;
  final WatchHistoryRepository? history;
  final bool embedded;
  final bool active;
  final int sectionRequest;
  final ValueChanged<MyPageAction>? onAction;
  final List<Drama>? dramas;
  final ValueChanged<Drama>? onDramaSelected;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late final WatchHistoryRepository _history =
      widget.history ?? SharedPreferencesWatchHistoryRepository();
  late Future<Duration?> _position;
  int _section = 0;
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
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
  void didUpdateWidget(covariant MyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        (!oldWidget.active || oldWidget.drama.id != widget.drama.id)) {
      setState(_refreshPosition);
    }
    if (widget.sectionRequest != oldWidget.sectionRequest) {
      setState(() => _section = widget.initialSection);
    }
  }

  void _act(MyPageAction action) {
    if (widget.embedded) {
      widget.onAction?.call(action);
    } else {
      Navigator.pop(context, action);
    }
  }

  Future<void> _showLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1D22),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.language)),
            for (final (code, label) in [
              ('en', l10n.english),
              ('zh', l10n.simplifiedChinese),
            ])
              ListTile(
                title: Text(label),
                onTap: () {
                  context.read<LocaleController>().select(code);
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
    final content = SafeArea(
      bottom: !widget.embedded,
      child: Column(
        children: [
          _topBar(l10n),
          Expanded(
            child: FutureBuilder<Duration?>(
              future: _position,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final total = widget.duration > Duration.zero
                    ? widget.duration
                    : const Duration(seconds: 12);
                final fraction =
                    (position.inMilliseconds / total.inMilliseconds).clamp(
                      0.0,
                      1.0,
                    );
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    _profile(l10n),
                    const SizedBox(height: 22),
                    _continueCard(l10n, fraction, position, total),
                    const SizedBox(height: 26),
                    _library(l10n, position, total, fraction),
                    const SizedBox(height: 26),
                    _preferences(l10n),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'LUMADRAMA · DEMO',
                        style: TextStyle(
                          color: Color(0xFF77777D),
                          fontSize: 10,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (!widget.embedded) _bottomNav(l10n),
        ],
      ),
    );
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: widget.embedded
          ? content
          : Scaffold(backgroundColor: const Color(0xFF0B0C10), body: content),
    );
  }

  Widget _topBar(AppLocalizations l10n) => SizedBox(
    height: 54,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: _orange, size: 27),
          const SizedBox(width: 7),
          Text(
            l10n.myTab,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          IconButton(
            tooltip: l10n.search,
            onPressed: () => _act(MyPageAction.discover),
            icon: const Icon(Icons.search_rounded, size: 23),
          ),
          const SizedBox(width: 6),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF2C2D33),
            child: Icon(Icons.person_rounded, color: Colors.white, size: 19),
          ),
        ],
      ),
    ),
  );

  Widget _profile(AppLocalizations l10n) => Row(
    children: [
      const CircleAvatar(
        radius: 30,
        backgroundColor: Color(0xFF32343A),
        child: Icon(Icons.person_rounded, color: Colors.white, size: 34),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.localViewer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.localDemoProfile,
              style: const TextStyle(color: Color(0xFFAAAAB0), fontSize: 11),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF24252A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(l10n.demo, style: const TextStyle(fontSize: 11)),
      ),
    ],
  );

  Widget _continueCard(
    AppLocalizations l10n,
    double fraction,
    Duration position,
    Duration total,
  ) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFF201B1E),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: _orange, size: 17),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.continueWatching,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              l10n.episodeProgress(1, widget.drama.episodes.length),
              style: const TextStyle(color: Color(0xFFFFA38F), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _poster(width: 75, height: 96),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.drama.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.dramaTag,
                    style: const TextStyle(
                      color: Color(0xFFB4AFB1),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.watchedPercent((fraction * 100).round()),
                    style: const TextStyle(
                      color: Color(0xFFE7DEDD),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 4,
                      backgroundColor: const Color(0xFF444046),
                      color: _orange,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_clock(position)} / ${_clock(total)}',
                    style: const TextStyle(
                      color: Color(0xFFABA6AA),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _act(MyPageAction.resume),
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(37),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(l10n.resume),
          ),
        ),
      ],
    ),
  );

  Widget _library(
    AppLocalizations l10n,
    Duration position,
    Duration total,
    double fraction,
  ) {
    final tabs = [l10n.history, l10n.watchlist, l10n.likedTab];
    final filters = [l10n.all, l10n.inProgress, l10n.completed];
    final hasHistory =
        _filter == 0 ||
        (_filter == 1 && fraction < 0.99) ||
        (_filter == 2 && fraction >= 0.99);
    final engagement = context.watch<EngagementController>();
    final markedDramas = (widget.dramas ?? [widget.drama]).where((drama) {
      return _section == 1
          ? engagement.isSaved(drama.id)
          : engagement.isLiked(drama.id);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < tabs.length; index++) ...[
                InkWell(
                  onTap: () => setState(() => _section = index),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: _section == index
                          ? _orange
                          : const Color(0xFFE4DBDD),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (index < tabs.length - 1) const SizedBox(width: 18),
              ],
            ],
          ),
        ),
        const SizedBox(height: 17),
        if (_section == 0)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < filters.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(filters[index]),
                      selected: _filter == index,
                      onSelected: (_) => setState(() => _filter = index),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF242328),
                      selectedColor: _orange,
                      labelStyle: TextStyle(
                        color: _filter == index
                            ? Colors.white
                            : const Color(0xFFD5CED0),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide.none,
                    ),
                  ),
              ],
            ),
          ),
        if (_section == 0) const SizedBox(height: 11),
        if (_section == 0 && hasHistory)
          InkWell(
            onTap: () => _act(MyPageAction.resume),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1C21),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _poster(width: 74, height: 103),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.drama.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.dramaTag,
                          style: const TextStyle(
                            color: Color(0xFFAAA7AC),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          '${l10n.episodeLabel(1)} · ${_clock(position)} / ${_clock(total)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFA18D),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: Color(0xFF313137),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: _orange,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_section != 0 && markedDramas.isNotEmpty)
          for (final drama in markedDramas) ...[
            _markedDramaCard(drama, l10n),
            const SizedBox(height: 9),
          ]
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Text(
              l10n.noSavedShows,
              style: const TextStyle(color: Color(0xFFAAA7AC)),
            ),
          ),
      ],
    );
  }

  Widget _markedDramaCard(Drama drama, AppLocalizations l10n) => InkWell(
    onTap: () {
      if (widget.onDramaSelected != null) {
        widget.onDramaSelected!(drama);
      } else if (drama.id == widget.drama.id) {
        _act(MyPageAction.resume);
      }
    },
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1C21),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              drama.posterAsset,
              width: 74,
              height: 103,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drama.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  l10n.episodeCount(drama.episodes.length),
                  style: const TextStyle(
                    color: Color(0xFFAAA7AC),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        ],
      ),
    ),
  );

  Widget _preferences(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.preferences.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFCEBBB9),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 12),
      Material(
        color: const Color(0xFF1B1C21),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: const Icon(
            Icons.translate_rounded,
            color: Color(0xFFFFBC65),
          ),
          title: Text(l10n.appLanguage),
          subtitle: Text(l10n.language),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Localizations.localeOf(context).languageCode == 'zh'
                    ? l10n.simplifiedChinese
                    : l10n.english,
                style: const TextStyle(color: Color(0xFFFFB2A1), fontSize: 11),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
          onTap: _showLanguage,
        ),
      ),
    ],
  );

  Widget _bottomNav(AppLocalizations l10n) => Container(
    height: 63,
    decoration: const BoxDecoration(
      color: Color(0xFF0D0D11),
      border: Border(top: BorderSide(color: Color(0xFF242329))),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(
          icon: Icons.play_circle_outline_rounded,
          label: l10n.homeTab,
          onTap: () => Navigator.pop(context, MyPageAction.home),
        ),
        _NavItem(
          icon: Icons.explore_outlined,
          label: l10n.discoverTab,
          onTap: () => Navigator.pop(context, MyPageAction.discover),
        ),
        _NavItem(
          icon: Icons.video_library_outlined,
          label: l10n.myTab,
          selected: true,
          onTap: () {},
        ),
      ],
    ),
  );

  Widget _poster({required double width, required double height}) => ClipRRect(
    borderRadius: BorderRadius.circular(7),
    child: Image.asset(
      widget.drama.posterAsset,
      width: width,
      height: height,
      fit: BoxFit.cover,
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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

String _clock(Duration duration) {
  final seconds = duration.inSeconds;
  return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}

const _orange = Color(0xFFFF5B3D);
