import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Guruji's chosen app language (English, Hindi or Marathi).
/// Reading [languageCode] synchronously (no BuildContext needed) is what
/// makes the `tr()` helper in lib/l10n/tr.dart usable from anywhere,
/// including StatelessWidget build methods deep in the tree.
class LocaleService {
  LocaleService._();

  static const supportedLanguages = ['en', 'hi', 'mr'];
  static const _prefsKey = 'app_language';
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));

  static String get languageCode => localeNotifier.value.languageCode;
  static bool get isHindi => languageCode == 'hi';
  static bool get isMarathi => languageCode == 'mr';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && supportedLanguages.contains(saved)) {
      localeNotifier.value = Locale(saved);
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    localeNotifier.value = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, languageCode);
  }
}
