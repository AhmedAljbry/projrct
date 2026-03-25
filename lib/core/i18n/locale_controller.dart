import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  final SharedPreferences _prefs;

  Locale _locale;

  LocaleController(this._prefs)
      : _locale = Locale(_prefs.getString(_localeKey) ?? 'ar');

  Locale get locale => _locale;

  bool get isAr => _locale.languageCode == 'ar';

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    await _prefs.setString(_localeKey, newLocale.languageCode);
    notifyListeners();
  }

  void toggleLocale() {
    final newLocale = isAr ? const Locale('en') : const Locale('ar');
    setLocale(newLocale);
  }
}
