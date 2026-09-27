import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> load() async {
    try {
      final code = await _preferences.getString('ui.locale');
      _locale = switch (code) {
        'en' => const Locale('en'),
        'zh' => const Locale('zh'),
        _ => null,
      };
      notifyListeners();
    } catch (_) {
      // The system locale remains usable if preferences are unavailable.
    }
  }

  Future<void> select(String code) async {
    _locale = switch (code) {
      'en' => const Locale('en'),
      'zh' => const Locale('zh'),
      _ => null,
    };
    notifyListeners();
    try {
      await _preferences.setString('ui.locale', code);
    } catch (_) {
      // Preference persistence is best effort for this prototype.
    }
  }
}
