import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_drama/features/catalog/data/catalog_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all mock entries reuse one bundled local demo video', () async {
    final dramas = await DemoCatalogRepository().fetchDramas();
    expect(dramas, hasLength(3));
    expect(dramas.every((drama) => drama.episodes.length == 3), isTrue);
    final paths = {
      for (final drama in dramas)
        for (final episode in drama.episodes) episode.assetPath,
    };
    expect(paths, {'assets/media/demo_clip.mp4'});
    expect(
      dramas.every(
        (drama) => drama.episodes.every((episode) => episode.isFree),
      ),
      isTrue,
    );
    final bytes = await rootBundle.load(paths.single);
    expect(bytes.lengthInBytes, greaterThan(1000000));
  });
}
