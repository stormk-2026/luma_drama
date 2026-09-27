// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'LumaDrama';

  @override
  String get demo => '演示';

  @override
  String get homeHeadline => '即刻观看';

  @override
  String get homeSubtitle => '免费短剧预览。';

  @override
  String get mediaNotice => '用户提供的本地演示视频 · 免费观看';

  @override
  String get featuredDemo => '精选 · 技术演示';

  @override
  String get demoTitle => '信号';

  @override
  String get demoSynopsis => '使用本地视频进行播放预览，后续有素材再增加剧集。';

  @override
  String get homeTab => '首页';

  @override
  String get openQuickMenu => '打开快捷菜单';

  @override
  String get quickAccess => '快捷入口';

  @override
  String get currentSeries => '当前短剧';

  @override
  String get discoverTab => '找剧';

  @override
  String get searchDiscover => '搜索短剧、演员、类型…';

  @override
  String get featured => '精选';

  @override
  String get suspense => '悬疑';

  @override
  String get romance => '都市爱情';

  @override
  String get actionGenre => '动作';

  @override
  String get filter => '筛选';

  @override
  String get topCharts => '排行榜';

  @override
  String get newReleases => '新剧';

  @override
  String get trendingMicroDramas => '热门短剧';

  @override
  String get seeAll => '查看全部';

  @override
  String get artworkOnly => '海报展示';

  @override
  String get artworkOnlyNotice => '这张海报仅用于目录展示，暂时没有可播放视频。';

  @override
  String get videoPending => '视频待提供';

  @override
  String get watchNow => '免费观看';

  @override
  String get noSearchResults => '没有匹配的短剧。';

  @override
  String get demoCatalogNotice => '三部 mock 剧复用同一条本地演示视频。';

  @override
  String get myTab => '我的';

  @override
  String get localViewer => '本地观众';

  @override
  String get localDemoProfile => '本地演示档案';

  @override
  String get continueWatching => '继续观看';

  @override
  String watchedPercent(int percent) {
    return '已观看 $percent%';
  }

  @override
  String get resume => '继续播放';

  @override
  String get history => '历史';

  @override
  String get watchlist => '追剧';

  @override
  String get likedTab => '喜欢';

  @override
  String get all => '全部';

  @override
  String get inProgress => '未看完';

  @override
  String get completed => '已看完';

  @override
  String get noSavedShows => '这里还没有剧集。';

  @override
  String get preferences => '偏好设置';

  @override
  String get appLanguage => '应用语言';

  @override
  String get followingTab => '关注';

  @override
  String get animatedTab => '漫剧';

  @override
  String get recommendedTab => '推荐';

  @override
  String get noCategoryDramas => '这个分类暂时没有剧集。';

  @override
  String get trendingTab => '热门';

  @override
  String get liveActionTab => '真人剧';

  @override
  String get search => '搜索';

  @override
  String get free => '免费';

  @override
  String get mute => '静音';

  @override
  String get unmute => '取消静音';

  @override
  String get like => '喜欢';

  @override
  String get save => '收藏';

  @override
  String get comments => '评论';

  @override
  String get share => '分享';

  @override
  String get localOnlyComments => '仅在本机可见';

  @override
  String get noComments => '还没有评论。';

  @override
  String get writeComment => '写评论';

  @override
  String get postComment => '发布';

  @override
  String get shareFailed => '无法打开系统分享面板。';

  @override
  String get nowPlaying => '正在播放';

  @override
  String get watchFullscreen => '横屏全屏观看';

  @override
  String get exitFullscreen => '退出全屏';

  @override
  String get pictureInPicture => '画中画';

  @override
  String get pipUnavailable => '此设备无法使用画中画';

  @override
  String get originalTag => '原创';

  @override
  String get dramaTag => '短剧';

  @override
  String episodeLabel(int number) {
    return '第 $number 集';
  }

  @override
  String get exploreSeries => '查看剧集';

  @override
  String episodeCount(int count) {
    return '$count 集';
  }

  @override
  String technicalDemoCount(int count) {
    return '免费试看 · $count 集';
  }

  @override
  String get episodes => '选集';

  @override
  String get watchEpisodeOne => '观看第 1 集';

  @override
  String continueEpisode(int number) {
    return '续看第 $number 集';
  }

  @override
  String get freeTestMedia => '复用同一演示视频 · 免费';

  @override
  String get lockedStoreUnavailable => '已锁定 · 商店未配置';

  @override
  String get freeTestClip => '免费测试片';

  @override
  String get locked => '已锁定';

  @override
  String get freeSamplesNotice => '前两集免费 · 商店配置待完成';

  @override
  String get demoTestMedia => '免费 · 同一演示视频';

  @override
  String episodeProgress(int number, int total) {
    return '第 $number / $total 集';
  }

  @override
  String get testVideoNotice => '自行生成的技术测试视频';

  @override
  String lockedTitle(int number) {
    return '第 $number 集已锁定';
  }

  @override
  String get lockedBody => '完成商店与服务端验单配置后才能解锁。本演示目前不处理付款。';

  @override
  String get playbackError => '此视频暂时无法播放。';

  @override
  String get catalogError => '剧目列表加载失败。';

  @override
  String get noStories => '暂无剧目。';

  @override
  String get retry => '重试';

  @override
  String get backToSeries => '返回剧集详情';

  @override
  String get nextEpisode => '下一集';

  @override
  String get pause => '暂停';

  @override
  String get play => '播放';

  @override
  String get seekVideo => '拖动播放进度';

  @override
  String get seekFailed => '无法调整播放进度。';

  @override
  String get captions => '字幕';

  @override
  String get captionsOff => '关闭字幕';

  @override
  String get englishCaptions => '英文字幕';

  @override
  String get chineseCaptions => '简体中文字幕';

  @override
  String get language => '界面语言';

  @override
  String get systemLanguage => '跟随系统';

  @override
  String get english => 'English';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get episodeOneTitle => '初见微光';

  @override
  String get episodeTwoTitle => '新的频率';

  @override
  String get episodeThreeTitle => '越过边界';

  @override
  String get episodeFourTitle => '回声之后';
}
