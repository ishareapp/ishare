// lib/core/extensions/translation_extension.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

extension TranslationExtension on BuildContext {
  // Easy translation from anywhere in the app
  String tr(String key) {
    return Provider.of<LanguageProvider>(this, listen: false).translate(key);
  }
  
  // Get current language code
  String get currentLanguage {
    return Provider.of<LanguageProvider>(this, listen: false).currentLanguage;
  }
  
  // Change language
  Future<void> changeLanguage(String languageCode) {
    return Provider.of<LanguageProvider>(this, listen: false).changeLanguage(languageCode);
  }
}

// Usage examples:
/*
// In any widget:
Text(context.tr('home'))
Text(context.tr('bookings'))
ElevatedButton(
  onPressed: () {},
  child: Text(context.tr('book_now')),
)

// Change language:
await context.changeLanguage('fr');

// Get current language:
String lang = context.currentLanguage;
*/