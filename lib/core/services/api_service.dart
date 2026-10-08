import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart'; // تأكد من استيراد كلاس الثوابت الخاص بك

class ApiService {
  // بناء الرابط الكامل سواء تم تمرير رابط كامل أو مسار نسبي
  static Uri _buildUri(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Uri.parse(url);
    }
    // دمج BaseURL مع المسار النسبي
    final baseUrl = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;
    final path = url.startsWith('/') ? url : '/$url';
    return Uri.parse('$baseUrl$path');
  }

  // تجميع الهيدرز المطلوبة والتأكد من إرفاق التوكين
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // طلب POST
  static Future<http.Response> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    return await http.post(
      _buildUri(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // طلب GET
  static Future<http.Response> get(String url) async {
    final headers = await _getHeaders();
    return await http.get(_buildUri(url), headers: headers);
  }

  // طلب PUT
  static Future<http.Response> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    return await http.put(
      _buildUri(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // طلب DELETE
  static Future<http.Response> delete(String url) async {
    final headers = await _getHeaders();
    return await http.delete(_buildUri(url), headers: headers);
  }
}
