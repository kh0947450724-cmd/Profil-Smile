import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // أو الحزمة التي تستخدمها للترجمة

extension OrderStatusExtension on String {
  /// تحويل حالة الطلب القادمة من API إلى نص مترجم بحسب لغة التطبيق
  String toTranslatedStatus(BuildContext context) {
    final cleanStatus = trim().toLowerCase();

    switch (cleanStatus) {
      case 'received':
        return 'received'.tr();
      case 'in_production':
      case 'in-production':
        return 'in_production'.tr();
      case 'pending':
        return 'pending'.tr();
      case 'delivered':
        return 'delivered'.tr();
      case 'approved':
        return 'approved'.tr();
      case 'needs_redo':
        return 'needs_redo'.tr();
      default:
        return this; // في حال كانت حالة غير معروفة
    }
  }
}
