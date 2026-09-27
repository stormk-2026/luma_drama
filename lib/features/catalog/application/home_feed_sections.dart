import '../domain/drama.dart';

enum HomeFeedCategory { following, animated, liveAction, recommended }

/// Maps catalog entries into home feeds without owning playback or UI state.
class HomeFeedSections {
  HomeFeedSections(this.dramas, {this.followedDramaIds = const {}});

  final List<Drama> dramas;
  final Set<String> followedDramaIds;

  List<int> indicesFor(HomeFeedCategory category) => [
    for (var index = 0; index < dramas.length; index++)
      if (dramas[index].episodes.isNotEmpty &&
          switch (category) {
            HomeFeedCategory.following => followedDramaIds.contains(
              dramas[index].id,
            ),
            HomeFeedCategory.animated =>
              dramas[index].format == DramaFormat.animated,
            HomeFeedCategory.liveAction =>
              dramas[index].format == DramaFormat.liveAction,
            HomeFeedCategory.recommended => true,
          })
        index,
  ];

  Drama dramaAt(HomeFeedCategory category, int categoryIndex) =>
      dramas[indicesFor(category)[categoryIndex]];
}
