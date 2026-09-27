import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/app_localizations.dart';
import '../../catalog/application/home_feed_sections.dart';
import '../../catalog/domain/drama.dart';
import '../../catalog/presentation/discover_page.dart';
import '../../catalog/presentation/drama_detail_page.dart';
import '../../library/data/watch_history_repository.dart';
import '../../library/presentation/my_page.dart';
import '../../engagement/application/engagement_controller.dart';
import '../../engagement/data/platform_share_service.dart';
import '../../engagement/presentation/drama_comments_sheet.dart';
import '../application/playback_session.dart';
import '../application/playback_queue.dart';
import '../data/video_player_port.dart';
import '../data/android_picture_in_picture.dart';
import '../domain/player_port.dart';
import 'seek_progress_bar.dart';
import 'category_swipe_region.dart';
import 'home_feed_header.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.drama,
    required this.initialIndex,
    this.homeMode = false,
    this.embedded = false,
    this.active = true,
    this.resumeRequest = 0,
    this.backRequest = 0,
    this.onDiscover,
    this.onMy,
    this.onSearch,
    this.onMenu,
    this.feedDramas,
    this.onDramaChanged,
    this.onImmersiveChanged,
  });

  final Drama drama;
  final int initialIndex;
  final bool homeMode;
  final bool embedded;
  final bool active;
  final int resumeRequest;
  final int backRequest;
  final VoidCallback? onDiscover;
  final VoidCallback? onMy;
  final VoidCallback? onSearch;
  final VoidCallback? onMenu;
  final List<Drama>? feedDramas;
  final ValueChanged<Drama>? onDramaChanged;
  final ValueChanged<bool>? onImmersiveChanged;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  late PageController _pages;
  late final PlaybackQueue _queue;
  late final HomeFeedSections _homeSections;
  late List<int> _visibleIndices;
  HomeFeedCategory _category = HomeFeedCategory.recommended;
  int _categoryRequest = 0;
  late final PlaybackSession _session;
  final WatchHistoryRepository _history =
      SharedPreferencesWatchHistoryRepository();
  VideoPlayerPort? _trackedPlayer;
  Episode? _trackedEpisode;
  Drama? _trackedDrama;
  DateTime _lastProgressWrite = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _pendingWrite = Future<void>.value();
  int _pageRequest = 0;
  bool _muted = false;
  bool _stoppedAtFeedEnd = false;
  VideoPlayerPort? _scrubbingPlayer;
  final AndroidPictureInPicture _pictureInPicture = AndroidPictureInPicture();
  bool _fullscreen = false;
  bool _pip = false;
  bool _pipPreparing = false;

  bool get _immersive => _fullscreen || _pip || _pipPreparing;

  void _notifyImmersive() => widget.onImmersiveChanged?.call(_immersive);

  Future<void> _setFullscreen(bool value) async {
    if (_fullscreen == value || !mounted) return;
    setState(() => _fullscreen = value);
    _notifyImmersive();
    try {
      await SystemChrome.setPreferredOrientations(
        value
            ? [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : [DeviceOrientation.portraitUp],
      );
      await SystemChrome.setEnabledSystemUIMode(
        value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    } catch (_) {
      if (value && mounted) {
        setState(() => _fullscreen = false);
        _notifyImmersive();
      }
    }
  }

  Future<void> _enterPip() async {
    if (_pip || _pipPreparing) return;
    if (_session.active is! VideoPlayerPort) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pipUnavailable)),
      );
      return;
    }
    if (_fullscreen) await _setFullscreen(false);
    setState(() => _pipPreparing = true);
    _notifyImmersive();
    await WidgetsBinding.instance.endOfFrame;
    bool entered = false;
    try {
      entered = await _pictureInPicture.enter();
    } catch (_) {
      // Android reports unavailable for devices without PiP support.
    }
    if (!mounted) return;
    if (entered) {
      setState(() {
        _pip = true;
        _pipPreparing = false;
      });
      _notifyImmersive();
      _session.setAppResumed(true);
    } else {
      setState(() => _pipPreparing = false);
      _notifyImmersive();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pipUnavailable)),
      );
    }
  }

  void _onPipChanged(bool enabled) {
    if (!mounted) return;
    setState(() {
      _pip = enabled;
      _pipPreparing = false;
    });
    _notifyImmersive();
    _session.setAppResumed(
      enabled ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
  }

  Future<void> _preparePlayer(Episode episode, PlayerPort player) async {
    if (player is! VideoPlayerPort) return;
    final index = _session.currentIndex;
    final drama = _queue.entryAt(index).drama;
    try {
      final saved = await _history.positionFor(
        demoProfileId,
        drama.id,
        episode.id,
      );
      if (saved != null && _session.active == player) {
        await player.controller.seekTo(
          clampResumePosition(saved, player.controller.value.duration),
        );
      }
    } catch (_) {
      // A local preference failure does not prevent playback.
    }
    if (_session.active != player) return;
    _trackedPlayer = player;
    _trackedEpisode = episode;
    _trackedDrama = drama;
    _lastProgressWrite = DateTime.now();
    var completionHandled = false;
    var completionProgressSaved = false;
    player.controller.addListener(() {
      if (_session.active != player || !player.controller.value.isInitialized) {
        return;
      }
      if (player.controller.value.isCompleted && !completionProgressSaved) {
        completionProgressSaved = true;
        unawaited(
          _queueProgress(drama, episode, player.controller.value.duration),
        );
      }
      if (!completionHandled &&
          player.controller.value.isCompleted &&
          _session.canAutoAdvance &&
          _session.currentIndex == index) {
        completionHandled = true;
        unawaited(_advanceAfterEnd(player, index));
      }
      final now = DateTime.now();
      if (now.difference(_lastProgressWrite) < const Duration(seconds: 5)) {
        return;
      }
      _lastProgressWrite = now;
      unawaited(
        _queueProgress(drama, episode, player.controller.value.position),
      );
    });
  }

  Future<void> _advanceAfterEnd(VideoPlayerPort player, int index) async {
    if (!mounted || _session.active != player || !_session.canAutoAdvance) {
      return;
    }
    final next = _visibleIndices.indexOf(index) + 1;
    if (next <= 0 || next >= _visibleIndices.length) {
      _stoppedAtFeedEnd = true;
      _session.setUserWantsPlay(false);
      return;
    }
    final pages = _pages;
    try {
      if (!pages.hasClients) return;
      await pages.animateToPage(
        next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
      // A category change can detach the old page controller mid-animation.
    }
  }

  Future<void> _queueProgress(Drama drama, Episode episode, Duration position) {
    _pendingWrite = _pendingWrite
        .then(
          (_) => _history.save(demoProfileId, drama.id, episode.id, position),
        )
        .catchError((Object _) {
          // Playback continues if local history cannot be stored.
        });
    return _pendingWrite;
  }

  Future<void> _saveCurrentProgress() {
    final player = _trackedPlayer;
    final episode = _trackedEpisode;
    final drama = _trackedDrama;
    if (player == null ||
        episode == null ||
        drama == null ||
        !player.controller.value.isInitialized) {
      return _pendingWrite;
    }
    return _queueProgress(drama, episode, player.controller.value.position);
  }

  Future<void> _selectEpisode(int index) async {
    final request = ++_pageRequest;
    _session.setRouteVisible(false);
    _cancelScrub();
    await _saveCurrentProgress();
    if (request != _pageRequest || !mounted) return;
    await _session.select(index);
    if (request == _pageRequest && mounted) {
      _session.setRouteVisible(widget.active && _visibleIndices.isNotEmpty);
    }
  }

  void _shiftCategory(int offset) {
    if (!widget.homeMode) return;
    final next = _category.index + offset;
    if (next < 0) {
      widget.onMenu?.call();
      return;
    }
    if (next >= HomeFeedCategory.values.length) return;
    unawaited(_selectCategory(HomeFeedCategory.values[next]));
  }

  Future<void> _selectCategory(HomeFeedCategory category) async {
    if (!widget.homeMode || category == _category) return;
    final request = ++_categoryRequest;
    ++_pageRequest;
    _session.setRouteVisible(false);
    _cancelScrub();
    await _saveCurrentProgress();
    if (!mounted || request != _categoryRequest) return;

    final oldPages = _pages;
    final indices = _homeSections.indicesFor(category);
    setState(() {
      _category = category;
      _visibleIndices = indices;
      _pages = PageController();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => oldPages.dispose());

    if (indices.isEmpty) return;
    widget.onDramaChanged?.call(_queue.entryAt(indices.first).drama);
    if (_session.currentIndex != indices.first) {
      await _session.select(indices.first);
    }
    if (mounted && request == _categoryRequest) {
      if (_stoppedAtFeedEnd) {
        _stoppedAtFeedEnd = false;
        _session.setUserWantsPlay(true);
      }
      _session.setRouteVisible(widget.active);
    }
  }

  void _beginScrub(VideoPlayerPort player) {
    if (_session.active != player) return;
    _scrubbingPlayer = player;
    _session.setOverlayOpen(true);
  }

  void _cancelScrub() {
    if (_scrubbingPlayer == null) return;
    _scrubbingPlayer = null;
    _session.setOverlayOpen(false);
  }

  Future<void> _seekTo(VideoPlayerPort player, Duration position) async {
    if (_scrubbingPlayer != player || _session.active != player) return;
    try {
      await _session.playbackSettled;
      if (_scrubbingPlayer != player || _session.active != player) return;
      await player.controller.seekTo(position);
      if (_session.active == player) await _saveCurrentProgress();
    } catch (_) {
      if (mounted && _session.active == player) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.seekFailed)));
      }
    } finally {
      if (_scrubbingPlayer == player) _cancelScrub();
    }
  }

  Future<void> _leave() async {
    await _saveCurrentProgress();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pictureInPicture.setStateListener(_onPipChanged);
    _queue = widget.feedDramas == null
        ? PlaybackQueue.series(widget.drama)
        : PlaybackQueue.home(widget.feedDramas!);
    _homeSections = HomeFeedSections([
      for (final entry in _queue.entries) entry.drama,
    ]);
    _visibleIndices = widget.homeMode
        ? _homeSections.indicesFor(_category)
        : List<int>.generate(_queue.length, (index) => index);
    _pages = PageController(initialPage: widget.initialIndex);
    _session = PlaybackSession(
      episodes: [for (final entry in _queue.entries) entry.episode],
      factory: VideoPlayerPort.new,
      canPlay: (episode) => episode.isFree,
      prepare: _preparePlayer,
    );
    if (!widget.active || _visibleIndices.isEmpty) {
      _session.setRouteVisible(false);
    }
    unawaited(_selectEpisode(widget.initialIndex));
  }

  @override
  void didUpdateWidget(covariant PlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _session.setRouteVisible(widget.active && _visibleIndices.isNotEmpty);
      if (!widget.active) {
        _cancelScrub();
        unawaited(_saveCurrentProgress());
      }
    }
    if (oldWidget.resumeRequest != widget.resumeRequest) {
      _session.setUserWantsPlay(true);
    }
    if (oldWidget.backRequest != widget.backRequest) {
      final request = widget.backRequest;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.backRequest == request) {
          if (_fullscreen) {
            unawaited(_setFullscreen(false));
          } else {
            _shiftCategory(-1);
          }
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_saveCurrentProgress());
    _session.setAppResumed(
      state == AppLifecycleState.resumed || _pip || _pipPreparing,
    );
    if (state != AppLifecycleState.resumed) _cancelScrub();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pictureInPicture.setStateListener(null);
    if (_fullscreen) {
      unawaited(
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
      );
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    unawaited(_saveCurrentProgress());
    _session.setRouteVisible(false);
    _cancelScrub();
    unawaited(_session.close());
    _pages.dispose();
    super.dispose();
  }

  Future<void> _openDetail() async {
    _session.setRouteVisible(false);
    await _session.playbackSettled;
    await _saveCurrentProgress();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DramaDetailPage(drama: _queue.entryAt(_session.currentIndex).drama),
      ),
    );
    if (mounted) _session.setRouteVisible(widget.active);
  }

  Future<void> _showEpisodes() async {
    if (widget.feedDramas != null) {
      await _openDetail();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    _session.setOverlayOpen(true);
    await _session.playbackSettled;
    if (!mounted) {
      _session.setOverlayOpen(false);
      return;
    }
    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF202024),
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    l10n.episodes,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _queue.length,
                    itemBuilder: (context, index) {
                      final episode = _queue.entryAt(index).episode;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF3A3030),
                          child: Text('${episode.number}'),
                        ),
                        title: Text(l10n.episodeLabel(episode.number)),
                        subtitle: Text(l10n.freeTestMedia),
                        trailing: const Icon(Icons.play_arrow_rounded),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          unawaited(
                            _pages.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      _session.setOverlayOpen(false);
    }
  }

  Future<void> _showMy({int initialSection = 0}) async {
    if (widget.embedded) {
      widget.onMy?.call();
      return;
    }
    _session.setRouteVisible(false);
    await _session.playbackSettled;
    await _saveCurrentProgress();
    if (!mounted) return;
    final port = _session.active;
    final drama = _queue.entryAt(_session.currentIndex).drama;
    final duration = port is VideoPlayerPort
        ? port.controller.value.duration
        : Duration.zero;
    final action = await Navigator.of(context).push<MyPageAction>(
      MaterialPageRoute(
        builder: (_) => MyPage(
          drama: drama,
          duration: duration,
          initialSection: initialSection,
        ),
      ),
    );
    if (!mounted) return;
    if (action == MyPageAction.discover) {
      await _showDiscover();
    } else {
      _session.setRouteVisible(true);
    }
    if (action == MyPageAction.resume) _session.setUserWantsPlay(true);
  }

  Future<void> _showSearch() async {
    if (widget.embedded) {
      widget.onSearch?.call();
      return;
    }
    await _showDiscover(focusSearch: true);
  }

  Future<void> _showDiscover({bool focusSearch = false}) async {
    if (widget.embedded) {
      widget.onDiscover?.call();
      return;
    }
    _session.setRouteVisible(false);
    await _session.playbackSettled;
    await _saveCurrentProgress();
    if (!mounted) return;
    final port = _session.active;
    final duration = port is VideoPlayerPort
        ? port.controller.value.duration
        : Duration.zero;
    final action = await Navigator.of(context).push<DiscoverPageAction>(
      MaterialPageRoute(
        builder: (_) => DiscoverPage(
          drama: widget.drama,
          duration: duration,
          focusSearch: focusSearch,
        ),
      ),
    );
    if (!mounted) return;
    if (action == DiscoverPageAction.detail) {
      await _openDetail();
    } else if (action == DiscoverPageAction.my ||
        action == DiscoverPageAction.watchlist) {
      await _showMy(
        initialSection: action == DiscoverPageAction.watchlist ? 1 : 0,
      );
    } else {
      _session.setRouteVisible(true);
      if (action == DiscoverPageAction.resume) {
        _session.setUserWantsPlay(true);
      }
    }
  }

  Future<void> _toggleMute() async {
    final port = _session.active;
    if (port is! VideoPlayerPort) return;
    final next = !_muted;
    await port.controller.setVolume(next ? 0 : 1);
    if (mounted) setState(() => _muted = next);
  }

  Future<void> _showComments(Drama drama) async {
    _session.setOverlayOpen(true);
    await _session.playbackSettled;
    if (!mounted) {
      _session.setOverlayOpen(false);
      return;
    }
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF232328),
        showDragHandle: true,
        builder: (_) => DramaCommentsSheet(drama: drama),
      );
    } finally {
      _session.setOverlayOpen(false);
    }
  }

  Future<void> _shareDrama(Drama drama) async {
    _session.setOverlayOpen(true);
    await _session.playbackSettled;
    try {
      await const PlatformShareService().shareDrama(drama);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.shareFailed)),
        );
      }
    } finally {
      _session.setOverlayOpen(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementController>();
    final category = _category;
    final indices = _visibleIndices;
    final pages = _pages;
    final content = AnimatedBuilder(
      animation: _session,
      builder: (context, _) => indices.isEmpty && widget.homeMode
          ? _buildEmptyCategory(context)
          : PageView.builder(
              key: ValueKey(category),
              controller: pages,
              scrollDirection: Axis.vertical,
              itemCount: indices.length,
              onPageChanged: (position) {
                if (category != _category) return;
                final index = indices[position];
                widget.onDramaChanged?.call(_queue.entryAt(index).drama);
                unawaited(_selectEpisode(index));
              },
              itemBuilder: (context, position) =>
                  _buildEpisode(context, indices[position], engagement),
            ),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: widget.embedded
            ? content
            : Scaffold(backgroundColor: Colors.black, body: content),
      ),
    );
  }

  Widget _buildEmptyCategory(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CategorySwipeRegion(
      key: const Key('home-empty-swipe'),
      onShift: _shiftCategory,
      child: ColoredBox(
        color: const Color(0xFF111214),
        child: SafeArea(
          child: Column(
            children: [
              HomeFeedHeader(
                l10n: l10n,
                category: _category,
                onCategorySelected: (value) =>
                    unawaited(_selectCategory(value)),
                onCategoryShift: _shiftCategory,
                onSearch: _showSearch,
                onMy: _showMy,
                onMenu: widget.onMenu,
              ),
              const Spacer(),
              const Icon(
                Icons.video_library_outlined,
                size: 48,
                color: Colors.white38,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.noCategoryDramas,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.demoCatalogNotice,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisode(
    BuildContext context,
    int index,
    EngagementController engagement,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final entry = _queue.entryAt(index);
    final drama = entry.drama;
    final episode = entry.episode;
    final selected = index == _session.currentIndex;
    final port = selected ? _session.active : null;
    final videoPort = port is VideoPlayerPort ? port : null;
    final ready = videoPort?.controller.value.isInitialized ?? false;
    Widget? video;
    if (ready) {
      video = GestureDetector(
        onTap: () => _session.setUserWantsPlay(!_session.userWantsPlay),
        child: FittedBox(
          fit: _immersive ? BoxFit.contain : BoxFit.cover,
          child: SizedBox(
            width: videoPort!.controller.value.size.width,
            height: videoPort.controller.value.size.height,
            child: VideoPlayer(videoPort.controller),
          ),
        ),
      );
      if (widget.homeMode) {
        video = CategorySwipeRegion(
          key: selected ? const Key('home-video-swipe') : null,
          onShift: _shiftCategory,
          child: video,
        );
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_immersive)
          const ColoredBox(color: Colors.black)
        else if (widget.homeMode && !ready)
          CategorySwipeRegion(
            key: selected ? const Key('home-video-swipe') : null,
            onShift: _shiftCategory,
            child: Image.asset(drama.posterAsset, fit: BoxFit.cover),
          )
        else
          Image.asset(drama.posterAsset, fit: BoxFit.cover),
        ?video,
        if (!_immersive)
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Colors.transparent,
                    Color(0x22000000),
                    Color(0xE6000000),
                  ],
                  stops: [0, 0.28, 0.56, 1],
                ),
              ),
            ),
          ),
        if (selected && _session.loading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B45)),
          ),
        if (selected && ready && !_session.userWantsPlay && !_pip)
          Center(
            child: IconButton.filled(
              iconSize: 48,
              onPressed: () => _session.setUserWantsPlay(true),
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ),
        if (widget.homeMode && (_pip || _pipPreparing))
          const SizedBox.expand()
        else if (widget.homeMode && _fullscreen)
          _FullscreenControls(
            l10n: l10n,
            controller: ready ? videoPort!.controller : null,
            onClose: () => unawaited(_setFullscreen(false)),
            onPip: _pictureInPicture.isPlatformSupported
                ? () => unawaited(_enterPip())
                : null,
            onScrubStart: ready ? () => _beginScrub(videoPort!) : null,
            onSeek: ready ? (position) => _seekTo(videoPort!, position) : null,
          )
        else if (widget.homeMode)
          _StitchHomeOverlay(
            l10n: l10n,
            drama: drama,
            episode: episode,
            controller: ready ? videoPort!.controller : null,
            liked: engagement.isLiked(drama.id),
            saved: engagement.isSaved(drama.id),
            muted: _muted,
            category: _category,
            onCategorySelected: (value) => unawaited(_selectCategory(value)),
            onCategoryShift: _shiftCategory,
            onDetail: _openDetail,
            onDiscover: _showDiscover,
            onEpisodes: _showEpisodes,
            onMy: _showMy,
            onSearch: _showSearch,
            onMenu: widget.onMenu,
            onMute: _toggleMute,
            onLike: () => engagement.toggleLiked(drama.id),
            onSave: () => engagement.toggleSaved(drama.id),
            onComments: () => _showComments(drama),
            onShare: () => _shareDrama(drama),
            onFullscreen: () => unawaited(_setFullscreen(true)),
            onPip: _pictureInPicture.isPlatformSupported
                ? () => unawaited(_enterPip())
                : null,
            onScrubStart: ready ? () => _beginScrub(videoPort!) : null,
            onSeek: ready ? (position) => _seekTo(videoPort!, position) : null,
            showBottomNav: !widget.embedded,
          )
        else
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!widget.homeMode)
                        IconButton(
                          onPressed: () => unawaited(_leave()),
                          tooltip: l10n.backToSeries,
                          icon: const Icon(Icons.arrow_back_rounded),
                        )
                      else
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Color(0xFFFF6B45),
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.homeMode ? l10n.appName : drama.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.language,
                        onPressed: _showMy,
                        icon: const Icon(Icons.language_rounded),
                      ),
                    ],
                  ),
                  if (widget.homeMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.homeTab,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 22),
                        TextButton(
                          onPressed: _openDetail,
                          child: Text(
                            l10n.discoverTab,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  if (selected && _session.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FilledButton(
                        onPressed: () => unawaited(_session.select(index)),
                        child: Text('${l10n.playbackError}  ${l10n.retry}'),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.demoTestMedia,
                              style: const TextStyle(
                                color: Color(0xFFFFB199),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              drama.title,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              drama.synopsis,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          IconButton.filledTonal(
                            tooltip: l10n.exploreSeries,
                            onPressed: _openDetail,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.info_outline_rounded),
                          ),
                          const SizedBox(height: 8),
                          IconButton.filledTonal(
                            tooltip: l10n.episodes,
                            onPressed: _showEpisodes,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.grid_view_rounded),
                          ),
                          const SizedBox(height: 8),
                          IconButton.filledTonal(
                            tooltip: _session.userWantsPlay
                                ? l10n.pause
                                : l10n.play,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: ready
                                ? () => _session.setUserWantsPlay(
                                    !_session.userWantsPlay,
                                  )
                                : null,
                            icon: Icon(
                              _session.userWantsPlay
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: _showEpisodes,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      '${l10n.episodeProgress(episode.number, drama.episodes.length)}  ·  ${l10n.episodes}',
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                  ),
                  SeekProgressBar(
                    valueListenable: ready ? videoPort!.controller : null,
                    semanticsLabel: l10n.seekVideo,
                    showTimes: false,
                    onScrubStart: ready ? () => _beginScrub(videoPort!) : null,
                    onSeek: ready
                        ? (position) => _seekTo(videoPort!, position)
                        : null,
                  ),
                  if (widget.homeMode) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BottomAction(
                          icon: Icons.home_rounded,
                          label: l10n.homeTab,
                          selected: true,
                          onTap: () {},
                        ),
                        _BottomAction(
                          icon: Icons.explore_outlined,
                          label: l10n.discoverTab,
                          onTap: _showDiscover,
                        ),
                        _BottomAction(
                          icon: Icons.person_outline_rounded,
                          label: l10n.myTab,
                          onTap: _showMy,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FullscreenControls extends StatelessWidget {
  const _FullscreenControls({
    required this.l10n,
    required this.controller,
    required this.onClose,
    required this.onPip,
    required this.onScrubStart,
    required this.onSeek,
  });

  final AppLocalizations l10n;
  final VideoPlayerController? controller;
  final VoidCallback onClose;
  final VoidCallback? onPip;
  final VoidCallback? onScrubStart;
  final Future<void> Function(Duration)? onSeek;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.exitFullscreen,
              onPressed: onClose,
              icon: const Icon(Icons.close_fullscreen_rounded),
            ),
            const Spacer(),
            if (onPip != null)
              IconButton(
                tooltip: l10n.pictureInPicture,
                onPressed: onPip,
                icon: const Icon(Icons.picture_in_picture_alt_outlined),
              ),
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SeekProgressBar(
            valueListenable: controller,
            semanticsLabel: l10n.seekVideo,
            compactIdle: true,
            onScrubStart: onScrubStart,
            onSeek: onSeek,
          ),
        ),
      ],
    ),
  );
}

class _StitchHomeOverlay extends StatelessWidget {
  const _StitchHomeOverlay({
    required this.l10n,
    required this.drama,
    required this.episode,
    required this.controller,
    required this.liked,
    required this.saved,
    required this.muted,
    required this.category,
    required this.onCategorySelected,
    required this.onCategoryShift,
    required this.onDetail,
    required this.onDiscover,
    required this.onEpisodes,
    required this.onMy,
    required this.onSearch,
    required this.onMenu,
    required this.onMute,
    required this.onLike,
    required this.onSave,
    required this.onComments,
    required this.onShare,
    required this.onFullscreen,
    required this.onPip,
    required this.onScrubStart,
    required this.onSeek,
    required this.showBottomNav,
  });

  final AppLocalizations l10n;
  final Drama drama;
  final Episode episode;
  final VideoPlayerController? controller;
  final bool liked;
  final bool saved;
  final bool muted;
  final HomeFeedCategory category;
  final ValueChanged<HomeFeedCategory> onCategorySelected;
  final ValueChanged<int> onCategoryShift;
  final VoidCallback onDetail;
  final VoidCallback onDiscover;
  final VoidCallback onEpisodes;
  final VoidCallback onMy;
  final VoidCallback onSearch;
  final VoidCallback? onMenu;
  final VoidCallback onMute;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComments;
  final VoidCallback onShare;
  final VoidCallback onFullscreen;
  final VoidCallback? onPip;
  final VoidCallback? onScrubStart;
  final Future<void> Function(Duration)? onSeek;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: showBottomNav,
    child: Column(
      children: [
        HomeFeedHeader(
          l10n: l10n,
          category: category,
          onCategorySelected: onCategorySelected,
          onCategoryShift: onCategoryShift,
          onSearch: onSearch,
          onMy: onMy,
          onMenu: onMenu,
          onMute: onMute,
          muted: muted,
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetaChip(text: l10n.freeTestMedia, accent: true),
                    const SizedBox(height: 5),
                    Text(
                      drama.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      drama.synopsis,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                      ),
                    ),
                    Tooltip(
                      message: l10n.exploreSeries,
                      child: TextButton(
                        onPressed: onDetail,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28),
                          foregroundColor: const Color(0xFFFFA18B),
                        ),
                        child: Text(
                          l10n.exploreSeries,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RailAction(
                    key: const Key('rail-save'),
                    icon: saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    label: l10n.save,
                    selected: saved,
                    onTap: onSave,
                  ),
                  _RailAction(
                    key: const Key('rail-comments'),
                    icon: Icons.mode_comment_outlined,
                    label: l10n.comments,
                    onTap: onComments,
                  ),
                  _RailAction(
                    key: const Key('rail-like'),
                    icon: liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: l10n.like,
                    selected: liked,
                    onTap: onLike,
                  ),
                  _RailAction(
                    key: const Key('rail-share'),
                    icon: Icons.share_rounded,
                    label: l10n.share,
                    onTap: onShare,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Tooltip(
              message: l10n.watchFullscreen,
              child: TextButton.icon(
                onPressed: onFullscreen,
                icon: const Icon(Icons.screen_rotation_outlined, size: 15),
                label: Text(l10n.watchFullscreen),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  textStyle: const TextStyle(fontSize: 11),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            if (onPip != null)
              IconButton(
                tooltip: l10n.pictureInPicture,
                onPressed: onPip,
                visualDensity: VisualDensity.compact,
                iconSize: 17,
                icon: const Icon(Icons.picture_in_picture_alt_outlined),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Tooltip(
            message: l10n.episodes,
            child: InkWell(
              onTap: onEpisodes,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xE6212125),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_outline_rounded, size: 19),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${l10n.episodeLabel(episode.number)} · ${l10n.nowPlaying}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${l10n.episodes} (${drama.episodes.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SeekProgressBar(
            valueListenable: controller,
            semanticsLabel: l10n.seekVideo,
            onScrubStart: onScrubStart,
            onSeek: onSeek,
            compactIdle: true,
          ),
        ),
        const SizedBox(height: 2),
        if (showBottomNav)
          Container(
            height: 62,
            color: const Color(0xF20C0C0F),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomAction(
                  icon: Icons.play_circle_outline_rounded,
                  label: l10n.homeTab,
                  selected: true,
                  onTap: () {},
                ),
                _BottomAction(
                  icon: Icons.explore_outlined,
                  label: l10n.discoverTab,
                  onTap: onDiscover,
                ),
                _BottomAction(
                  icon: Icons.video_library_outlined,
                  label: l10n.myTab,
                  onTap: onMy,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.text, this.accent = false});
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xB51F1F22),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: accent ? const Color(0xFFFFA18B) : Colors.white70,
      ),
    ),
  );
}

class _RailAction extends StatelessWidget {
  const _RailAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.filledTonal(
        tooltip: label,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xB719191B),
          foregroundColor: selected ? const Color(0xFFFF6B45) : Colors.white,
        ),
        icon: Icon(icon, size: 22),
      ),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          shadows: [Shadow(blurRadius: 6, color: Colors.black)],
        ),
      ),
    ],
  );
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
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
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected ? const Color(0xFFFF6B45) : Colors.white70,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? const Color(0xFFFF6B45) : Colors.white70,
            ),
          ),
        ],
      ),
    ),
  );
}
