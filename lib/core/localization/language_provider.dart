import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('ar'); // Default to Arabic or English

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language');
    if (savedLang != null) {
      _currentLocale = Locale(savedLang);
      notifyListeners();
    }
  }

  Future<void> toggleLanguage() async {
    final newLang = _currentLocale.languageCode == 'en' ? 'ar' : 'en';
    _currentLocale = Locale(newLang);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', newLang);
  }
}


