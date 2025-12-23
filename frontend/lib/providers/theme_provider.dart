import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  late ThemeData _themeData;

  ThemeProvider() {
    _themeData = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    _loadThemePreference();
  }

  ThemeData get themeData => _themeData;
  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? true;
    _themeData = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _themeData = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);

    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    _themeData = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);

    notifyListeners();
  }
}
