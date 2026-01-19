import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _languageKey = 'language_code';

  LanguageProvider() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> _saveLanguagePreference(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  Locale get locale => _locale;

  void setLanguage(String languageCode) {
    _locale = Locale(languageCode);
    _saveLanguagePreference(languageCode);
    notifyListeners();
  }
}
