import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('es'),
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'es': {
      'app_title': 'Domótica App',
      'control_menu_tooltip': 'Abrir menú',
      'control_menu_ai_consumption': 'Consumo de IA',
      'control_menu_frequency': 'Actual: cada {seconds}s',
      'control_menu_language': 'Cambiar idioma',
      'control_menu_language_current': 'Actual: {language}',
      'language_spanish': 'Español',
      'language_english': 'Inglés',
      'action_logout': 'Cerrar sesión',
    },
    'en': {
      'app_title': 'Domotics App',
      'control_menu_tooltip': 'Open menu',
      'control_menu_ai_consumption': 'AI consumption',
      'control_menu_frequency': 'Current: every {seconds}s',
      'control_menu_language': 'Change language',
      'control_menu_language_current': 'Current: {language}',
      'language_spanish': 'Spanish',
      'language_english': 'English',
      'action_logout': 'Sign out',
    },
  };

  String t(String key, {Map<String, String>? params}) {
    final fallback = _localizedValues['es'] ?? const {};
    final values = _localizedValues[locale.languageCode] ?? fallback;
    var value = values[key] ?? fallback[key] ?? key;
    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }
    return value;
  }

  String literal({required String es, required String en}) {
    return locale.languageCode == 'en' ? en : es;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
