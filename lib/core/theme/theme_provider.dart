import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePrefKey = 'theme_preference';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoaded = false;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _isLoaded;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
       // We can't rely on system directly here without context, so we expose the mode itself.
       return false; // Fallback
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveThemeToPrefs();
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTheme = prefs.getString(_themePrefKey);
    
    if (savedTheme != null) {
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    }
    
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String themeString = 'system';
    if (_themeMode == ThemeMode.dark) themeString = 'dark';
    if (_themeMode == ThemeMode.light) themeString = 'light';
    
    await prefs.setString(_themePrefKey, themeString);
  }
}
