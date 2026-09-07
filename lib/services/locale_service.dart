import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Guruji's chosen app language (English or Hindi). Reading
/// [isHindi] synchronously (no BuildContext needed) is what makes the `tr()`
/// helper in lib/l10n/tr.dart usable from anywhere, including StatelessWidget
/// build methods deep in the tree.
class LocaleService {
  LocaleService._();

  static const _prefsKey = 'app_language';
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));

  static bool get isHindi => localeNotifier.value.languageCode == 'hi';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_prefsKey) == 'hi') {
      localeNotifier.value = const Locale('hi');
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    localeNotifier.value = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, languageCode);
  }
}
