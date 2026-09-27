// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'LumaDrama';

  @override
  String get demo => 'DEMO';

  @override
  String get homeHeadline => 'Watch now';

  @override
  String get homeSubtitle => 'Free short drama preview.';

  @override
  String get mediaNotice => 'User-provided local demo video · Free preview';

  @override
  String get featuredDemo => 'FEATURED · TECHNICAL DEMO';

  @override
  String get demoTitle => 'The Signal';

  @override
  String get demoSynopsis =>
      'A short local video preview. More episodes can be added when media is available.';

  @override
  String get homeTab => 'Home';

  @override
  String get openQuickMenu => 'Open quick menu';

  @override
  String get quickAccess => 'Quick access';

  @override
  String get currentSeries => 'Current series';

  @override
  String get discoverTab => 'Discover';

  @override
  String get searchDiscover => 'Search dramas, actors, genres...';

  @override
  String get featured => 'Featured';

  @override
  String get suspense => 'Suspense';

  @override
  String get romance => 'Romance';

  @override
  String get actionGenre => 'Action';

  @override
  String get filter => 'Filter';

  @override
  String get topCharts => 'Top Charts';

  @override
  String get newReleases => 'New Releases';

  @override
  String get trendingMicroDramas => 'Trending Micro-Dramas';

  @override
  String get seeAll => 'See All';

  @override
  String get artworkOnly => 'Artwork';

  @override
  String get artworkOnlyNotice =>
      'This is a visual catalog item. No video is available yet.';

  @override
  String get videoPending => 'Video pending';

  @override
  String get watchNow => 'Watch free';

  @override
  String get noSearchResults => 'No matching dramas.';

  @override
  String get demoCatalogNotice =>
      'Three mock dramas reuse the same local demo video.';

  @override
  String get myTab => 'My';

  @override
  String get localViewer => 'Local Viewer';

  @override
  String get localDemoProfile => 'Local demo profile';

  @override
  String get continueWatching => 'Continue Watching';

  @override
  String watchedPercent(int percent) {
    return 'Watched $percent%';
  }

  @override
  String get resume => 'Resume';

  @override
  String get history => 'History';

  @override
  String get watchlist => 'Watchlist';

  @override
  String get likedTab => 'Liked';

  @override
  String get all => 'All';

  @override
  String get inProgress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get noSavedShows => 'No shows here yet.';

  @override
  String get preferences => 'Preferences';

  @override
  String get appLanguage => 'App Language';

  @override
  String get followingTab => 'Following';

  @override
  String get animatedTab => 'Animated';

  @override
  String get recommendedTab => 'Recommended';

  @override
  String get noCategoryDramas => 'No dramas in this category yet.';

  @override
  String get trendingTab => 'Trending';

  @override
  String get liveActionTab => 'Live Action';

  @override
  String get search => 'Search';

  @override
  String get free => 'Free';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get like => 'Like';

  @override
  String get save => 'Save';

  @override
  String get comments => 'Comments';

  @override
  String get share => 'Share';

  @override
  String get localOnlyComments => 'Only visible on this device';

  @override
  String get noComments => 'No comments yet.';

  @override
  String get writeComment => 'Write a comment';

  @override
  String get postComment => 'Post';

  @override
  String get shareFailed => 'Could not open the share sheet.';

  @override
  String get nowPlaying => 'Playing now';

  @override
  String get watchFullscreen => 'Watch in landscape';

  @override
  String get exitFullscreen => 'Exit fullscreen';

  @override
  String get pictureInPicture => 'Picture in picture';

  @override
  String get pipUnavailable =>
      'Picture in picture is unavailable on this device';

  @override
  String get originalTag => 'Original';

  @override
  String get dramaTag => 'Short drama';

  @override
  String episodeLabel(int number) {
    return 'Episode $number';
  }

  @override
  String get exploreSeries => 'Explore series';

  @override
  String episodeCount(int count) {
    return '$count EPISODES';
  }

  @override
  String technicalDemoCount(int count) {
    return 'FREE PREVIEW · $count EPISODES';
  }

  @override
  String get episodes => 'Episodes';

  @override
  String get watchEpisodeOne => 'Watch episode 1';

  @override
  String continueEpisode(int number) {
    return 'Continue episode $number';
  }

  @override
  String get freeTestMedia => 'Same demo clip · free';

  @override
  String get lockedStoreUnavailable => 'Locked · store unavailable';

  @override
  String get freeTestClip => 'Free test clip';

  @override
  String get locked => 'Locked';

  @override
  String get freeSamplesNotice => 'Two free samples · store setup pending';

  @override
  String get demoTestMedia => 'FREE · SAME DEMO CLIP';

  @override
  String episodeProgress(int number, int total) {
    return 'EPISODE $number / $total';
  }

  @override
  String get testVideoNotice => 'Self-generated technical test video';

  @override
  String lockedTitle(int number) {
    return 'Episode $number is locked';
  }

  @override
  String get lockedBody =>
      'Unlocking will be available after store and verification setup. This demo does not process payments.';

  @override
  String get playbackError => 'This clip could not be played.';

  @override
  String get catalogError => 'The catalog could not be loaded.';

  @override
  String get noStories => 'No stories available yet.';

  @override
  String get retry => 'Retry';

  @override
  String get backToSeries => 'Back to series';

  @override
  String get nextEpisode => 'Next episode';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get seekVideo => 'Seek video';

  @override
  String get seekFailed => 'Could not change playback position.';

  @override
  String get captions => 'Captions';

  @override
  String get captionsOff => 'Captions off';

  @override
  String get englishCaptions => 'English captions';

  @override
  String get chineseCaptions => 'Chinese captions';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System';

  @override
  String get english => 'English';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get episodeOneTitle => 'First Light';

  @override
  String get episodeTwoTitle => 'A New Frequency';

  @override
  String get episodeThreeTitle => 'Crossing Over';

  @override
  String get episodeFourTitle => 'After the Echo';
}
