// lib/core/providers/language_provider.dart

import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  // Initialize language from storage
  Future<void> loadLanguage() async {
    _currentLanguage = await LanguageService.getLanguage();
    notifyListeners();
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await LanguageService.saveLanguage(languageCode);
    notifyListeners();
  }

  // Translate a key
  String translate(String key) {
    return LanguageService.translate(key, _currentLanguage);
  }

  // Short alias for translate
  String t(String key) => translate(key);
}