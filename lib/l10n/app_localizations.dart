import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'LumaDrama'**
  String get appName;

  /// No description provided for @demo.
  ///
  /// In en, this message translates to:
  /// **'DEMO'**
  String get demo;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Watch now'**
  String get homeHeadline;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free short drama preview.'**
  String get homeSubtitle;

  /// No description provided for @mediaNotice.
  ///
  /// In en, this message translates to:
  /// **'User-provided local demo video · Free preview'**
  String get mediaNotice;

  /// No description provided for @featuredDemo.
  ///
  /// In en, this message translates to:
  /// **'FEATURED · TECHNICAL DEMO'**
  String get featuredDemo;

  /// No description provided for @demoTitle.
  ///
  /// In en, this message translates to:
  /// **'The Signal'**
  String get demoTitle;

  /// No description provided for @demoSynopsis.
  ///
  /// In en, this message translates to:
  /// **'A short local video preview. More episodes can be added when media is available.'**
  String get demoSynopsis;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @openQuickMenu.
  ///
  /// In en, this message translates to:
  /// **'Open quick menu'**
  String get openQuickMenu;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get quickAccess;

  /// No description provided for @currentSeries.
  ///
  /// In en, this message translates to:
  /// **'Current series'**
  String get currentSeries;

  /// No description provided for @discoverTab.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTab;

  /// No description provided for @searchDiscover.
  ///
  /// In en, this message translates to:
  /// **'Search dramas, actors, genres...'**
  String get searchDiscover;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @suspense.
  ///
  /// In en, this message translates to:
  /// **'Suspense'**
  String get suspense;

  /// No description provided for @romance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get romance;

  /// No description provided for @actionGenre.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get actionGenre;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @topCharts.
  ///
  /// In en, this message translates to:
  /// **'Top Charts'**
  String get topCharts;

  /// No description provided for @newReleases.
  ///
  /// In en, this message translates to:
  /// **'New Releases'**
  String get newReleases;

  /// No description provided for @trendingMicroDramas.
  ///
  /// In en, this message translates to:
  /// **'Trending Micro-Dramas'**
  String get trendingMicroDramas;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @artworkOnly.
  ///
  /// In en, this message translates to:
  /// **'Artwork'**
  String get artworkOnly;

  /// No description provided for @artworkOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'This is a visual catalog item. No video is available yet.'**
  String get artworkOnlyNotice;

  /// No description provided for @videoPending.
  ///
  /// In en, this message translates to:
  /// **'Video pending'**
  String get videoPending;

  /// No description provided for @watchNow.
  ///
  /// In en, this message translates to:
  /// **'Watch free'**
  String get watchNow;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching dramas.'**
  String get noSearchResults;

  /// No description provided for @demoCatalogNotice.
  ///
  /// In en, this message translates to:
  /// **'Three mock dramas reuse the same local demo video.'**
  String get demoCatalogNotice;

  /// No description provided for @myTab.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get myTab;

  /// No description provided for @localViewer.
  ///
  /// In en, this message translates to:
  /// **'Local Viewer'**
  String get localViewer;

  /// No description provided for @localDemoProfile.
  ///
  /// In en, this message translates to:
  /// **'Local demo profile'**
  String get localDemoProfile;

  /// No description provided for @continueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get continueWatching;

  /// No description provided for @watchedPercent.
  ///
  /// In en, this message translates to:
  /// **'Watched {percent}%'**
  String watchedPercent(int percent);

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @watchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get watchlist;

  /// No description provided for @likedTab.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get likedTab;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @noSavedShows.
  ///
  /// In en, this message translates to:
  /// **'No shows here yet.'**
  String get noSavedShows;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @followingTab.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingTab;

  /// No description provided for @animatedTab.
  ///
  /// In en, this message translates to:
  /// **'Animated'**
  String get animatedTab;

  /// No description provided for @recommendedTab.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommendedTab;

  /// No description provided for @noCategoryDramas.
  ///
  /// In en, this message translates to:
  /// **'No dramas in this category yet.'**
  String get noCategoryDramas;

  /// No description provided for @trendingTab.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trendingTab;

  /// No description provided for @liveActionTab.
  ///
  /// In en, this message translates to:
  /// **'Live Action'**
  String get liveActionTab;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @localOnlyComments.
  ///
  /// In en, this message translates to:
  /// **'Only visible on this device'**
  String get localOnlyComments;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noComments;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get writeComment;

  /// No description provided for @postComment.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postComment;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the share sheet.'**
  String get shareFailed;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing now'**
  String get nowPlaying;

  /// No description provided for @watchFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Watch in landscape'**
  String get watchFullscreen;

  /// No description provided for @exitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get exitFullscreen;

  /// No description provided for @pictureInPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture in picture'**
  String get pictureInPicture;

  /// No description provided for @pipUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Picture in picture is unavailable on this device'**
  String get pipUnavailable;

  /// No description provided for @originalTag.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalTag;

  /// No description provided for @dramaTag.
  ///
  /// In en, this message translates to:
  /// **'Short drama'**
  String get dramaTag;

  /// No description provided for @episodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Episode {number}'**
  String episodeLabel(int number);

  /// No description provided for @exploreSeries.
  ///
  /// In en, this message translates to:
  /// **'Explore series'**
  String get exploreSeries;

  /// No description provided for @episodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} EPISODES'**
  String episodeCount(int count);

  /// No description provided for @technicalDemoCount.
  ///
  /// In en, this message translates to:
  /// **'FREE PREVIEW · {count} EPISODES'**
  String technicalDemoCount(int count);

  /// No description provided for @episodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodes;

  /// No description provided for @watchEpisodeOne.
  ///
  /// In en, this message translates to:
  /// **'Watch episode 1'**
  String get watchEpisodeOne;

  /// No description provided for @continueEpisode.
  ///
  /// In en, this message translates to:
  /// **'Continue episode {number}'**
  String continueEpisode(int number);

  /// No description provided for @freeTestMedia.
  ///
  /// In en, this message translates to:
  /// **'Same demo clip · free'**
  String get freeTestMedia;

  /// No description provided for @lockedStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Locked · store unavailable'**
  String get lockedStoreUnavailable;

  /// No description provided for @freeTestClip.
  ///
  /// In en, this message translates to:
  /// **'Free test clip'**
  String get freeTestClip;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @freeSamplesNotice.
  ///
  /// In en, this message translates to:
  /// **'Two free samples · store setup pending'**
  String get freeSamplesNotice;

  /// No description provided for @demoTestMedia.
  ///
  /// In en, this message translates to:
  /// **'FREE · SAME DEMO CLIP'**
  String get demoTestMedia;

  /// No description provided for @episodeProgress.
  ///
  /// In en, this message translates to:
  /// **'EPISODE {number} / {total}'**
  String episodeProgress(int number, int total);

  /// No description provided for @testVideoNotice.
  ///
  /// In en, this message translates to:
  /// **'Self-generated technical test video'**
  String get testVideoNotice;

  /// No description provided for @lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Episode {number} is locked'**
  String lockedTitle(int number);

  /// No description provided for @lockedBody.
  ///
  /// In en, this message translates to:
  /// **'Unlocking will be available after store and verification setup. This demo does not process payments.'**
  String get lockedBody;

  /// No description provided for @playbackError.
  ///
  /// In en, this message translates to:
  /// **'This clip could not be played.'**
  String get playbackError;

  /// No description provided for @catalogError.
  ///
  /// In en, this message translates to:
  /// **'The catalog could not be loaded.'**
  String get catalogError;

  /// No description provided for @noStories.
  ///
  /// In en, this message translates to:
  /// **'No stories available yet.'**
  String get noStories;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @backToSeries.
  ///
  /// In en, this message translates to:
  /// **'Back to series'**
  String get backToSeries;

  /// No description provided for @nextEpisode.
  ///
  /// In en, this message translates to:
  /// **'Next episode'**
  String get nextEpisode;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @seekVideo.
  ///
  /// In en, this message translates to:
  /// **'Seek video'**
  String get seekVideo;

  /// No description provided for @seekFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change playback position.'**
  String get seekFailed;

  /// No description provided for @captions.
  ///
  /// In en, this message translates to:
  /// **'Captions'**
  String get captions;

  /// No description provided for @captionsOff.
  ///
  /// In en, this message translates to:
  /// **'Captions off'**
  String get captionsOff;

  /// No description provided for @englishCaptions.
  ///
  /// In en, this message translates to:
  /// **'English captions'**
  String get englishCaptions;

  /// No description provided for @chineseCaptions.
  ///
  /// In en, this message translates to:
  /// **'Chinese captions'**
  String get chineseCaptions;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @simplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get simplifiedChinese;

  /// No description provided for @episodeOneTitle.
  ///
  /// In en, this message translates to:
  /// **'First Light'**
  String get episodeOneTitle;

  /// No description provided for @episodeTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'A New Frequency'**
  String get episodeTwoTitle;

  /// No description provided for @episodeThreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Crossing Over'**
  String get episodeThreeTitle;

  /// No description provided for @episodeFourTitle.
  ///
  /// In en, this message translates to:
  /// **'After the Echo'**
  String get episodeFourTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
