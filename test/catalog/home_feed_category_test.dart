import 'package:flutter_test/flutter_test.dart';
import 'package:luma_drama/features/catalog/application/home_feed_sections.dart';
import 'package:luma_drama/features/catalog/data/catalog_repository.dart';

void main() {
  test(
    'home categories filter demo dramas without changing their media',
    () async {
      final dramas = await DemoCatalogRepository().fetchDramas();
      final sections = HomeFeedSections(dramas);

      expect(sections.indicesFor(HomeFeedCategory.recommended), [0, 1, 2]);
      expect(sections.indicesFor(HomeFeedCategory.animated), [0]);
      expect(sections.indicesFor(HomeFeedCategory.liveAction), [1, 2]);
      expect(sections.indicesFor(HomeFeedCategory.following), isEmpty);
      expect(
        sections.dramaAt(HomeFeedCategory.liveAction, 0).title,
        'City Lights & Velvet Nights',
      );
    },
  );
}
