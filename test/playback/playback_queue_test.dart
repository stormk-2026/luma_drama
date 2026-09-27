import 'package:flutter_test/flutter_test.dart';
import 'package:luma_drama/features/catalog/data/catalog_repository.dart';
import 'package:luma_drama/features/playback/application/playback_queue.dart';

void main() {
  test(
    'home feed advances between dramas, series player between episodes',
    () async {
      final dramas = await DemoCatalogRepository().fetchDramas();
      final home = PlaybackQueue.home(dramas);
      expect(home.length, 3);
      expect(home.entryAt(0).drama.id, dramas[0].id);
      expect(home.entryAt(1).drama.id, dramas[1].id);
      expect(home.entryAt(1).episode.number, 1);
      expect(home.nextIndex(0), 1);
      expect(home.nextIndex(2), isNull);

      final series = PlaybackQueue.series(dramas[0]);
      expect(series.length, 3);
      expect(series.entryAt(0).drama.id, series.entryAt(1).drama.id);
      expect(series.entryAt(1).episode.number, 2);
      expect(series.nextIndex(0), 1);
      expect(series.nextIndex(2), isNull);
    },
  );
}
