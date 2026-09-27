import '../domain/drama.dart';

abstract interface class CatalogRepository {
  Future<List<Drama>> fetchDramas();
}

class DemoCatalogRepository implements CatalogRepository {
  @override
  Future<List<Drama>> fetchDramas() async => const [
    Drama(
      id: 'the-signal-demo',
      title: 'The Signal',
      synopsis:
          'A mock series for testing vertical episode playback with one reused local clip.',
      posterAsset: 'assets/images/stitch_signal_poster_clean.png',
      format: DramaFormat.animated,
      episodes: [
        Episode(
          id: 'signal-01',
          number: 1,
          title: 'Episode 1',
          assetPath: 'assets/media/demo_clip.mp4',
          isFree: true,
        ),
        Episode(
          id: 'signal-02',
          number: 2,
          title: 'Episode 2',
          assetPath: 'assets/media/demo_clip.mp4',
          isFree: true,
        ),
        Episode(
          id: 'signal-03',
          number: 3,
          title: 'Episode 3',
          assetPath: 'assets/media/demo_clip.mp4',
          isFree: true,
        ),
      ],
    ),
    Drama(
      id: 'city-lights-demo',
      title: 'City Lights & Velvet Nights',
      synopsis:
          'A mock romance series using the same local video for navigation testing.',
      posterAsset: 'assets/images/stitch_city_poster_clean.png',
      format: DramaFormat.liveAction,
      episodes: [
        Episode(
          id: 'city-01',
          number: 1,
          title: 'Episode 1',
          assetPath: 'assets/media/demo_clip.mp4',
          isFree: true,
        ),
        Episode(
          id: 'city-02',
          number: 2,
          title: 'Episode 2',
          assetPath: 'assets/media/demo_clip.mp4',
          isFree: true,
        ),
        Episode(
          id: 'city-03',
          number: 3,
          title: 'Episode 3',
          assetPath: 'assets/media/demo_clip.mp4',
          isFree: true,
        ),
      ],
    ),
    Drama(
      id: 'vengeance-demo',
      title: 'Vengeance Rising',
      synopsis:
          'A mock action series using the same local video for navigation testing.',
      posterAsset: 'assets/images/stitch_vengeance_poster_clean.png',
      format: DramaFormat.liveAction,
      episodes: [
        Episode(
          id: 'vengeance-01',
          number: 1,
          title: 'Episode 1',
          assetPath: 'assets/media/demo_clip.mp4',
          isFree: true,
        ),
        Episode(
          id: 'vengeance-02',
          number: 2,
          title: 'Episode 2',
          assetPath: 'assets/media/demo_clip.mp4',
          isFree: true,
        ),
        Episode(
          id: 'vengeance-03',
          number: 3,
          title: 'Episode 3',
          assetPath: 'assets/media/demo_clip.mp4',
          isFree: true,
        ),
      ],
    ),
  ];
}
