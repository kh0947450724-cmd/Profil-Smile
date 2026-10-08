import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFirstTime = 'is_first_time';
  static const String _keyToken = 'auth_token';

  // حفظ أن المستخدم أتم شاشة الترحيب
  static Future<void> setFirstTimeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstTime, false);
  }

  // التحقق هل هي المرة الأولى لفتح التطبيق
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstTime) ?? true;
  }

  // حفظ Token تسجيل الدخول
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  // جلب Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // مسح التوكن (تسجيل الخروج)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }
}
