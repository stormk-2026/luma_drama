import 'package:flutter/foundation.dart';
import '../data/catalog_repository.dart';
import '../domain/drama.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this.repository);
  final CatalogRepository repository;

  List<Drama> dramas = const [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      dramas = await repository.fetchDramas();
    } catch (_) {
      error = 'The catalog could not be loaded.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
