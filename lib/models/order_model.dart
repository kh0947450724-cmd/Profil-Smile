import 'package:flutter/material.dart';
import 'package:profil_Smile/core/localization/app_localizations.dart';

class OrderModel {
  final int id;
  final String patientName;
  final String status;
  final String? notes;
  final String deliveryDate;
  final String createdAt;
  final String doctorName;
  final String prostheticTypeName;
  final String clinicName;

  OrderModel({
    required this.id,
    required this.patientName,
    required this.status,
    this.notes,
    required this.deliveryDate,
    required this.createdAt,
    required this.doctorName,
    required this.prostheticTypeName,
    required this.clinicName,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      patientName: json['patient_name'] ?? 'بدون اسم',
      status: json['status'] ?? 'received',
      notes: json['notes'],
      deliveryDate: json['delivery_date'] ?? '',
      createdAt: json['created_at'] ?? '',
      doctorName: json['doctor']?['name'] ?? 'طبيب غير محدد',
      prostheticTypeName: json['prosthetic_type']?['name'] ?? 'تعويض غير محدد',
      clinicName: json['clinic']?['name'] ?? 'عيادة غير محددة',
    );
  }

  // نص حالة الطلب بالعربي
  String get statusArabicText {
    switch (status.toLowerCase()) {
      case 'received':
        return 'تم الاستلام';
      case 'in_progress':
      case 'processing':
        return 'قيد التصنيع';
      case 'ready':
        return 'جاهز للتسليم';
      case 'delivered':
        return 'تم التسليم';
      default:
        return status;
    }
  }

  // لون حالة الطلب
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'received':
        return Colors.blue;
      case 'in_progress':
      case 'processing':
        return Colors.orange;
      case 'ready':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String getStatusTranslated(AppLocalizations loc) {
    switch (status.toLowerCase()) {
      case 'received':
        return loc.translate('status_received') ?? 'تم الاستلام';
      case 'in_progress':
      case 'processing':
        return loc.translate('status_in_progress') ?? 'قيد التصنيع';
      case 'ready':
        return loc.translate('status_ready') ?? 'جاهز للتسليم';
      case 'delivered':
        return loc.translate('status_delivered') ?? 'تم التسليم';
      default:
        return status;
    }
  }
}
