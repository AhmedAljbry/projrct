import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  final SharedPreferences _prefs;
  static const supportedLanguageCodes = <String>{'en', 'ar'};

  Locale _locale;

  LocaleController(this._prefs, {Locale? deviceLocale})
      : _locale = _resolveInitialLocale(_prefs, deviceLocale);

  Locale get locale => _locale;

  bool get isAr => _locale.languageCode == 'ar';
  bool get isEn => _locale.languageCode == 'en';

  static Locale _resolveInitialLocale(
    SharedPreferences prefs,
    Locale? deviceLocale,
  ) {
    final stored = prefs.getString(_localeKey);
    if (stored != null && supportedLanguageCodes.contains(stored)) {
      return Locale(stored);
    }

    final deviceLanguageCode = deviceLocale?.languageCode;
    if (deviceLanguageCode != null &&
        supportedLanguageCodes.contains(deviceLanguageCode)) {
      return Locale(deviceLanguageCode);
    }

    return const Locale('en');
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!supportedLanguageCodes.contains(newLocale.languageCode)) return;
    if (_locale.languageCode == newLocale.languageCode) return;
    _locale = Locale(newLocale.languageCode);
    await _prefs.setString(_localeKey, _locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleLocale() {
    final newLocale = isAr ? const Locale('en') : const Locale('ar');
    return setLocale(newLocale);
  }
}
