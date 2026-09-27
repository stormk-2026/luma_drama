enum DramaFormat { animated, liveAction }

class Episode {
  const Episode({
    required this.id,
    required this.number,
    required this.title,
    required this.assetPath,
    required this.isFree,
  });

  final String id;
  final int number;
  final String title;
  final String assetPath;
  final bool isFree;
}

class Drama {
  const Drama({
    required this.id,
    required this.title,
    required this.synopsis,
    required this.posterAsset,
    required this.episodes,
    this.format = DramaFormat.liveAction,
  });

  final String id;
  final String title;
  final String synopsis;
  final String posterAsset;
  final List<Episode> episodes;
  final DramaFormat format;
}
