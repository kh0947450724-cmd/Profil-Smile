import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/notification_model.dart';

// دالة التعامل مع الإشعارات في الخلفية (Top-Level Function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.addFromRemoteMessage(message);
}

class NotificationService {
  static const String _storageKey = 'app_notifications';
  static const int _maxStoredNotifications = 100;

  /// عدّاد الإشعارات غير المقروءة (للتحديث المباشر للواجهة)
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// قائمة الإشعارات الكاملة (للاستماع المباشر)
  static final ValueNotifier<List<AppNotification>> notificationsNotifier =
      ValueNotifier<List<AppNotification>>([]);

  // ═══════════════════════════════════════════════
  // تهيئة الخدمة والمستمعات (تُستدعى في main.dart)
  // ═══════════════════════════════════════════════
  static Future<void> initialize() async {
    // 1. تحميل الإشعارات المخزنة سابقاً
    await loadNotifications();

    // 2. طلب صلاحيات الإشعار لأجهزة iOS و Android 13+
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. ضبط خيارات إظهار الإشعار أثناء فتح التطبيق (Foreground Heads-up)
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // 4. تسجيل مستمع الإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. تهيئة مستمعي الواجهة (Foreground & Opened)
    initializeListeners();
  }

  // ═══════════════════════════════════════════════
  // تحميل الإشعارات من التخزين المحلي
  // ═══════════════════════════════════════════════
  static Future<List<AppNotification>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      notificationsNotifier.value = [];
      unreadCountNotifier.value = 0;
      return [];
    }
    final list = AppNotification.decodeList(raw);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notificationsNotifier.value = list;
    unreadCountNotifier.value = list.where((n) => !n.isRead).length;
    return list;
  }

  // ═══════════════════════════════════════════════
  // إضافة إشعار جديد
  // ═══════════════════════════════════════════════
  static Future<void> addNotification(AppNotification notification) async {
    final current = notificationsNotifier.value;
    // تجنّب التكرار
    if (current.any((n) => n.id == notification.id)) return;

    final updated = [notification, ...current];
    if (updated.length > _maxStoredNotifications) {
      updated.removeRange(_maxStoredNotifications, updated.length);
    }
    await _save(updated);
  }

  // ═══════════════════════════════════════════════
  // إضافة إشعار من FCM
  // ═══════════════════════════════════════════════
  static Future<void> addFromRemoteMessage(RemoteMessage message) async {
    final map = <String, dynamic>{
      'messageId': message.messageId,
      'notification': message.notification != null
          ? {
              'title': message.notification!.title,
              'body': message.notification!.body,
            }
          : null,
      'data': message.data,
    };

    final notification = AppNotification.fromRemoteMessage(map);
    await addNotification(notification);
  }

  // ═══════════════════════════════════════════════
  // تحديد كمقروء
  // ═══════════════════════════════════════════════
  static Future<void> markAsRead(String id) async {
    final updated = notificationsNotifier.value.map((n) {
      if (n.id == id) n.isRead = true;
      return n;
    }).toList();
    await _save(updated);
  }

  // ═══════════════════════════════════════════════
  // تحديد الكل كمقروء
  // ═══════════════════════════════════════════════
  static Future<void> markAllAsRead() async {
    final updated = notificationsNotifier.value.map((n) {
      n.isRead = true;
      return n;
    }).toList();
    await _save(updated);
  }

  // ═══════════════════════════════════════════════
  // حذف إشعار
  // ═══════════════════════════════════════════════
  static Future<void> deleteNotification(String id) async {
    final updated = notificationsNotifier.value
        .where((n) => n.id != id)
        .toList();
    await _save(updated);
  }

  // ═══════════════════════════════════════════════
  // حذف الكل
  // ═══════════════════════════════════════════════
  static Future<void> clearAll() async {
    await _save([]);
  }

  // ═══════════════════════════════════════════════
  // حفظ داخلي + إشعار المستمعين
  // ═══════════════════════════════════════════════
  static Future<void> _save(List<AppNotification> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, AppNotification.encodeList(list));

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notificationsNotifier.value = List.from(list);
    unreadCountNotifier.value = list.where((n) => !n.isRead).length;
  }

  // ═══════════════════════════════════════════════
  // تهيئة المستمعين (foreground + openedApp)
  // ═══════════════════════════════════════════════
  static void initializeListeners() {
    // إشعارات أثناء تشغيل التطبيق (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      addFromRemoteMessage(message);
    });

    // عند فتح التطبيق من إشعار (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      addFromRemoteMessage(message);
    });
  }
}
