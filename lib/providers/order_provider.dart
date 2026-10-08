// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository = OrderRepository();

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String _selectedClinicFilter = 'all';
  String _selectedStatusFilter = 'all';
  String _sortBy = 'date_asc';

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  // الحصول على الطلبات المفلترة مباشرة دون إرهاق الـ UI
  List<OrderModel> get filteredOrders {
    List<OrderModel> list = List.from(_orders);

    if (_selectedStatusFilter != 'all') {
      list = list
          .where(
            (o) =>
                (o.status ?? '').toLowerCase() ==
                _selectedStatusFilter.toLowerCase(),
          )
          .toList();
    }

    list.sort((a, b) {
      if (a.deliveryDate == null) return 1;
      if (b.deliveryDate == null) return -1;
      return _sortBy == 'date_asc'
          ? a.deliveryDate!.compareTo(b.deliveryDate!)
          : b.deliveryDate!.compareTo(a.deliveryDate!);
    });

    return list;
  }

  // طلبات اليوم فقط
  // List<OrderModel> get todayOrders {
  //   final now = DateTime.now();
  //   return _orders.where((o) {
  //     if (o.deliveryDate == null) return false;
  //     return o.deliveryDate!.year == now.year &&
  //         o.deliveryDate!.month == now.month &&
  //         o.deliveryDate!.day == now.day;
  //   }).toList();
  // }

  Future<void> fetchOrders({required bool isAdmin}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _repository.fetchOrders(isAdmin: isAdmin);
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilterStatus(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  Future<void> loadOrders({required bool isAdmin}) async {
    // خطوة A: قراءة الكاش أولاً وعرضه فوراً للمستخدم بدون انتظار السيرفر
    _orders = await _repository.getLocalOrders();
    notifyListeners();

    // إذا لم يكن هناك كاش مخزن، نظهر مؤشر التحميل
    if (_orders.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    // خطوة B: طلب البيانات الجديدة من الـ API في الخلفية
    try {
      final remoteOrders = await _repository.fetchRemoteOrders(
        isAdmin: isAdmin,
      );
      _orders = remoteOrders; // تحديث القائمة بالبيانات الجديدة
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners(); // إعادة رسم الشاشة بالبيانات الحديثة
    }
  }
}
