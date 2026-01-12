import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  late bool isDark;

  ThemeProvider() {
    // Initialize with device theme
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    isDark = brightness == Brightness.dark;
  }

  ThemeData get currentTheme =>
      isDark ? ThemeData.dark() : ThemeData.light();

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }
}