import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  LanguageController() {
    _loadPersistedLocale();
  }

  static const _storageKey = 'app_locale';
  static const _defaultLocale = Locale('es');

  Locale _locale = _defaultLocale;
  Locale get locale => _locale;

  Future<void> _loadPersistedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey);
    if (code == null) {
      return;
    }
    final newLocale = Locale(code);
    if (newLocale == _locale) {
      return;
    }
    _locale = newLocale;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) {
      return;
    }
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, locale.languageCode);
  }

  Future<void> toggleLocale() {
    final nextCode = _locale.languageCode == 'es' ? 'en' : 'es';
    return setLocale(Locale(nextCode));
  }
}
