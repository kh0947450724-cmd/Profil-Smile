import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _userType;
  String? _userName;

  bool get isLoading => _isLoading;
  String? get userType => _userType;
  String? get userName => _userName;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post(ApiConstants.login, {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        // استخراج البيانات بناءً على الاستجابة الفعلية من السيرفر
        final responseData = data['data'];
        final token = responseData['token'];
        _userType = responseData['user_type'];
        _userName = responseData['user'] != null
            ? responseData['user']['name']
            : '';

        // حفظ البيانات محلياً
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('token', token);
        if (_userType != null) await prefs.setString('user_type', _userType!);
        if (_userName != null) await prefs.setString('user_name', _userName!);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // الاستمرار في تسجيل الدخول تلقائياً
  Future<bool> checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      _userType = prefs.getString('user_type');
      _userName = prefs.getString('user_name');
      notifyListeners();
      return true;
    }
    return false;
  }

  // تسجيل الخروج
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _userType = null;
    _userName = null;
    notifyListeners();
  }
}
