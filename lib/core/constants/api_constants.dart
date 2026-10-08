class ApiConstants {
  // الرابط الأساسي للسيرفر
  static const String baseUrl = "https://magichandsapp.com/lab/api";

  // مسارات المصادقة
  static const String login = "$baseUrl/login";
  static const String me = "$baseUrl/me";
  static const String logout = "$baseUrl/logout";

  // مسارات العيادة (Clinic)
  static const String clinicOrders = "$baseUrl/clinic/orders";
  static const String clinicDoctors = '$baseUrl/clinic/doctors';

  // مسارات المدير (Admin)
  static const String adminOrders = "$baseUrl/admin/orders";
  static const String adminDashboardStats = "$baseUrl/admin/dashboard-stats";
  static const String adminClinics = "$baseUrl/admin/clinics";
  static const String adminDoctors = "$baseUrl/admin/doctors";
  static const String adminProstheticTypes = "$baseUrl/admin/prosthetic-types";

  // أنواع التعويضات العامة
  static const String prostheticTypes = '$baseUrl/clinic/prosthetic-types';
  static const String clinicProfile =
      '$baseUrl/clinic/profile'; // <-- إضافة هذا المسار
  static const String updateClinicProfile =
      '$baseUrl/clinic/profile'; // <-- إضافة هذا المسار
}
