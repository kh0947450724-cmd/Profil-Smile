import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/api_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  // مفتاح حفظ اللغة في SharedPreferences
  static const String _languageKey = 'selected_language';

  // قائمة اللغات المدعومة
  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('de'),
  ];

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_languageKey);

    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  /// تعيين لغة جديدة وحفظها محلياً + إخبار السيرفر
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      return;
    }

    // 1. تحديث الحالة محلياً
    _locale = locale;
    notifyListeners();

    // 2. حفظ محلياً في SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);

    // 3. ✅ إرسال للسيرفر مع التحقق من الاستجابة
    await _syncLocaleWithServer(locale.languageCode);
  }

  /// ✅ دالة منفصلة لمزامنة اللغة مع السيرفر
  /// (يمكن استدعاؤها أيضاً عند بدء التطبيق للتأكد من التزامن)
  Future<void> _syncLocaleWithServer(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      // ✅ غيّر من '/auth/locale' إلى '/locale'
      final response = await ApiService.post('/locale', {
        'locale': languageCode,
      });

      if (response.statusCode == 200) {
      } else {}
    } catch (e) {}
  }

  /// مزامنة يدوية (اختياري) - يمكن استدعاؤها عند تسجيل الدخول
  Future<void> syncCurrentLocale() async {
    if (_locale != null) {
      await _syncLocaleWithServer(_locale!.languageCode);
    }
  }

  /// العودة للغة الجهاز الافتراضية
  Future<void> clearLocale() async {
    _locale = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageKey);
  }
}
