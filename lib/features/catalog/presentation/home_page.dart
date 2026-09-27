import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/drama.dart';
import '../../library/presentation/my_page.dart';
import '../../playback/presentation/player_page.dart';
import 'catalog_controller.dart';
import 'discover_page.dart';
import 'drama_detail_page.dart';
import 'home_quick_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final l10n = AppLocalizations.of(context)!;

    if (catalog.loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (catalog.error != null || catalog.dramas.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(catalog.error == null ? l10n.noStories : l10n.catalogError),
              const SizedBox(height: 12),
              FilledButton(onPressed: catalog.load, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    return _HomeTabs(
      key: ValueKey(catalog.dramas.first.id),
      dramas: catalog.dramas,
    );
  }
}

/// The three primary destinations share a single route and keep their state.
class _HomeTabs extends StatefulWidget {
  const _HomeTabs({super.key, required this.dramas});

  final List<Drama> dramas;

  @override
  State<_HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<_HomeTabs> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Drama _currentDrama;
  int _tab = 0;
  int _searchRequest = 0;
  int _sectionRequest = 0;
  int _resumeRequest = 0;
  int _backRequest = 0;
  int _mySection = 0;
  bool _drawerOpen = false;
  bool _detailOpen = false;
  bool _videoImmersive = false;

  @override
  void initState() {
    super.initState();
    _currentDrama = widget.dramas.first;
  }

  void _select(
    int tab, {
    bool search = false,
    bool watchlist = false,
    bool resume = false,
    int? mySection,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _tab = tab;
      if (search) _searchRequest++;
      if (watchlist || mySection != null) {
        _mySection = mySection ?? 1;
        _sectionRequest++;
      }
      if (resume) _resumeRequest++;
    });
  }

  void _openMenu() {
    setState(() => _drawerOpen = true);
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectFromMenu(int tab, {int? mySection}) {
    _scaffoldKey.currentState?.closeDrawer();
    _select(tab, mySection: mySection);
  }

  Future<void> _openCurrentSeries() async {
    setState(() => _detailOpen = true);
    _scaffoldKey.currentState?.closeDrawer();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DramaDetailPage(drama: _currentDrama),
        ),
      );
    } finally {
      if (mounted) setState(() => _detailOpen = false);
    }
  }

  void _discoverAction(DiscoverPageAction action) {
    switch (action) {
      case DiscoverPageAction.home:
        _select(0);
      case DiscoverPageAction.my:
        _select(2);
      case DiscoverPageAction.watchlist:
        _select(2, watchlist: true);
      case DiscoverPageAction.resume:
        _select(0, resume: true);
      case DiscoverPageAction.detail:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DramaDetailPage(drama: _currentDrama),
          ),
        );
    }
  }

  void _myAction(MyPageAction action) {
    switch (action) {
      case MyPageAction.home:
        _select(0);
      case MyPageAction.discover:
        _select(1, search: true);
      case MyPageAction.resume:
        _select(0, resume: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_drawerOpen) {
          _scaffoldKey.currentState?.closeDrawer();
        } else if (_videoImmersive) {
          setState(() => _backRequest++);
        } else if (_tab != 0) {
          _select(0);
        } else {
          setState(() => _backRequest++);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF0B0C10),
        drawer: HomeQuickDrawer(
          drama: _currentDrama,
          onOpenSeries: _openCurrentSeries,
          onDiscover: () => _selectFromMenu(1),
          onHistory: () => _selectFromMenu(2, mySection: 0),
          onWatchlist: () => _selectFromMenu(2, mySection: 1),
          onLiked: () => _selectFromMenu(2, mySection: 2),
        ),
        drawerEnableOpenDragGesture: false,
        onDrawerChanged: (opened) {
          if (_drawerOpen != opened) setState(() => _drawerOpen = opened);
        },
        body: IndexedStack(
          index: _tab,
          children: [
            PlayerPage(
              drama: widget.dramas.first,
              feedDramas: widget.dramas,
              onDramaChanged: (drama) => setState(() => _currentDrama = drama),
              initialIndex: 0,
              homeMode: true,
              embedded: true,
              active: _tab == 0 && !_drawerOpen && !_detailOpen,
              resumeRequest: _resumeRequest,
              backRequest: _backRequest,
              onDiscover: () => _select(1),
              onMy: () => _select(2),
              onSearch: () => _select(1, search: true),
              onMenu: _openMenu,
              onImmersiveChanged: (value) =>
                  setState(() => _videoImmersive = value),
            ),
            DiscoverPage(
              drama: _currentDrama,
              dramas: widget.dramas,
              onDramaSelected: (drama) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DramaDetailPage(drama: drama),
                ),
              ),
              duration: Duration.zero,
              embedded: true,
              active: _tab == 1,
              searchRequest: _searchRequest,
              onAction: _discoverAction,
            ),
            MyPage(
              drama: _currentDrama,
              dramas: widget.dramas,
              onDramaSelected: (drama) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DramaDetailPage(drama: drama),
                ),
              ),
              duration: Duration.zero,
              initialSection: _mySection,
              sectionRequest: _sectionRequest,
              embedded: true,
              active: _tab == 2,
              onAction: _myAction,
            ),
          ],
        ),
        bottomNavigationBar: _videoImmersive
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  key: const Key('home-tabs-bar'),
                  height: 63,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D0D11),
                    border: Border(top: BorderSide(color: Color(0xFF242329))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TabButton(
                        key: const Key('tab-home'),
                        icon: Icons.play_circle_outline_rounded,
                        label: l10n.homeTab,
                        selected: _tab == 0,
                        onTap: () => _select(0),
                      ),
                      _TabButton(
                        key: const Key('tab-discover'),
                        icon: Icons.explore_outlined,
                        label: l10n.discoverTab,
                        selected: _tab == 1,
                        onTap: () => _select(1),
                      ),
                      _TabButton(
                        key: const Key('tab-my'),
                        icon: Icons.video_library_outlined,
                        label: l10n.myTab,
                        selected: _tab == 2,
                        onTap: () => _select(2),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 21,
            color: selected ? const Color(0xFFFF5C37) : const Color(0xFFABA5A8),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: selected
                  ? const Color(0xFFFF5C37)
                  : const Color(0xFFABA5A8),
            ),
          ),
        ],
      ),
    ),
  );
}
