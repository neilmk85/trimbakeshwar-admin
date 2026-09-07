import '../services/locale_service.dart';

/// Returns [hi] when the app's language is Hindi, [mr] (falling back to [hi]
/// when a Marathi translation hasn't been added yet at this call site) when
/// it's Marathi, otherwise [en].
///
/// Deliberately not keyed by an ID / ARB file — each call site carries its
/// translations inline, so there's nothing to keep in sync across files and
/// no shared registry that would conflict when many screens are converted
/// at once. The app is fully remounted on a language switch (see
/// AdminApp in main.dart), so a plain function read at build time is enough
/// — no BuildContext/InheritedWidget plumbing needed.
String tr(String en, String hi, [String? mr]) {
  if (LocaleService.isMarathi) return mr ?? hi;
  if (LocaleService.isHindi) return hi;
  return en;
}
