import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  late bool isDark;
  static const String _themeKey = 'theme_is_dark';

  ThemeProvider() {
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    isDark = brightness == Brightness.dark;
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool(_themeKey) ?? isDark;
    notifyListeners();
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  ThemeData get currentTheme =>
      isDark ? ThemeData.dark() : ThemeData.light();

  void toggleTheme() {
    isDark = !isDark;
    _saveThemePreference();
    notifyListeners();
  }
}