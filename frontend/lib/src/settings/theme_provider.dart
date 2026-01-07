import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool isDark = false;

  ThemeData get currentTheme =>
      isDark ? ThemeData.dark() : ThemeData.light();

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }
}