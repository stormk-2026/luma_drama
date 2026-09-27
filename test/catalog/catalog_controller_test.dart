import 'package:flutter_test/flutter_test.dart';
import 'package:luma_drama/features/catalog/data/catalog_repository.dart';
import 'package:luma_drama/features/catalog/domain/drama.dart';
import 'package:luma_drama/features/catalog/presentation/catalog_controller.dart';

void main() {
  test(
    'empty catalog is distinct from a failed load, and retry recovers',
    () async {
      final repo = ScriptedCatalogRepository();
      final controller = CatalogController(repo);
      await controller.load();
      expect(controller.dramas, isEmpty);
      expect(controller.error, isNull);

      repo.fail = true;
      await controller.load();
      expect(controller.error, isNotNull);

      repo.fail = false;
      repo.items = await DemoCatalogRepository().fetchDramas();
      await controller.load();
      expect(controller.error, isNull);
      expect(controller.dramas, hasLength(3));
      expect(controller.dramas.first.episodes.length, 3);
    },
  );
}

class ScriptedCatalogRepository implements CatalogRepository {
  bool fail = false;
  List<Drama> items = const [];

  @override
  Future<List<Drama>> fetchDramas() async {
    if (fail) throw StateError('offline');
    return items;
  }
}
