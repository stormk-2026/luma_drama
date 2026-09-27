import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../catalog/application/home_feed_sections.dart';
import 'category_swipe_region.dart';

/// Reused by playable and empty home feeds.
class HomeFeedHeader extends StatelessWidget {
  const HomeFeedHeader({
    super.key,
    required this.l10n,
    required this.category,
    required this.onCategorySelected,
    required this.onCategoryShift,
    required this.onSearch,
    required this.onMy,
    this.onMenu,
    this.onMute,
    this.muted = false,
  });

  final AppLocalizations l10n;
  final HomeFeedCategory category;
  final ValueChanged<HomeFeedCategory> onCategorySelected;
  final ValueChanged<int> onCategoryShift;
  final VoidCallback onSearch;
  final VoidCallback onMy;
  final VoidCallback? onMenu;
  final VoidCallback? onMute;
  final bool muted;

  String _label(HomeFeedCategory category) => switch (category) {
    HomeFeedCategory.following => l10n.followingTab,
    HomeFeedCategory.animated => l10n.animatedTab,
    HomeFeedCategory.liveAction => l10n.liveActionTab,
    HomeFeedCategory.recommended => l10n.recommendedTab,
  };

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            if (onMenu != null)
              IconButton(
                key: const Key('home-open-menu'),
                tooltip: l10n.openQuickMenu,
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded),
              ),
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5C37),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.homeTab,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              tooltip: l10n.search,
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              tooltip: l10n.myTab,
              onPressed: onMy,
              icon: const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFF3C3A3A),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        child: Row(
          children: [
            Expanded(
              child: CategorySwipeRegion(
                key: const Key('home-category-swipe'),
                onShift: onCategoryShift,
                child: Row(
                  children: [
                    for (final item in HomeFeedCategory.values)
                      Expanded(
                        child: InkWell(
                          key: Key('home-category-${item.name}'),
                          onTap: () => onCategorySelected(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _label(item),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: category == item
                                        ? const Color(0xFFFFA18B)
                                        : Colors.white60,
                                    fontSize: 12,
                                    fontWeight: category == item
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 18,
                                  height: 2,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: category == item
                                          ? const Color(0xFFFF5C37)
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (onMute != null)
              IconButton(
                tooltip: muted ? l10n.unmute : l10n.mute,
                onPressed: onMute,
                icon: Icon(
                  muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  size: 21,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
