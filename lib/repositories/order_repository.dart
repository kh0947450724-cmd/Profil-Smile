import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../models/order_model.dart';
import 'dart:convert';

class OrderRepository {
  Future<List<OrderModel>> fetchOrders({required bool isAdmin}) async {
    final url = isAdmin ? ApiConstants.adminOrders : ApiConstants.clinicOrders;
    final response = await ApiService.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? [];
      return list.map((json) => OrderModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static const String _cacheKey = 'cached_orders_list';

  // 1. جلب البيانات المخزنة محلياً (Offline / Cache)
  Future<List<OrderModel>> getLocalOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      return decoded.map((e) => OrderModel.fromJson(e)).toList();
    }
    return [];
  }

  // 2. جلب البيانات من السيرفر وحفظها في الكاش
  Future<List<OrderModel>> fetchRemoteOrders({required bool isAdmin}) async {
    final url = isAdmin ? ApiConstants.adminOrders : ApiConstants.clinicOrders;
    final response = await ApiService.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? [];

      // حفظ الاستجابة كـ String في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(list));

      return list.map((json) => OrderModel.fromJson(json)).toList();
    } else {
      throw Exception('فشل في جلب البيانات من السيرفر');
    }
  }
}
