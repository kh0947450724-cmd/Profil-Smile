import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:profil_Smile/screens/order_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/api_service.dart';
import 'core/services/notification_service.dart';
import 'providers/locale_provider.dart';
import 'screens/splash_screen.dart';

// Key للوصول إلى ScaffoldMessenger لإظهار SnackBar
final GlobalKey<ScaffoldMessengerState> adminMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Key للتحكم بالتنقل Navigator بدون الحاجة لـ BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final String? savedToken = prefs.getString('auth_token');

  // ✅ تحميل الإشعارات المخزّنة مسبقاً
  await NotificationService.loadNotifications();

  // ✅ تهيئة مستمعي إشعارات Firebase (foreground + openedApp)
  NotificationService.initializeListeners();

  // ✅ معالجة الإشعار الذي فتح التطبيق من حالة مغلقة (terminated)
  final RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();
  if (initialMessage != null) {
    await NotificationService.addFromRemoteMessage(initialMessage);
  }

  await _setupAdminFCM();

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> _sendFcmTokenToBackend(String token) async {
  try {
    final response = await ApiService.post('/update-fcm-token', {
      'fcm_token': token,
    });
  } catch (e) {}
}

Future<void> _setupAdminFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      await _sendFcmTokenToBackend(fcmToken);
    }

    messaging.onTokenRefresh.listen((newToken) async {
      await _sendFcmTokenToBackend(newToken);
    });

    // ═══════════════════════════════════════════════
    // إشعارات أثناء تشغيل التطبيق (foreground)
    // - تُحفظ في Service
    // - يُظهر SnackBar (النص بلغة المستخدم القادم من السيرفر)
    // ═══════════════════════════════════════════════
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // 1. حفظ الإشعار في القائمة المحلية
      NotificationService.addFromRemoteMessage(message);

      // 2. عرض SnackBar مباشرة (النص جاهز بلغة المستخدم)
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';

      if (title.isEmpty && body.isEmpty) return;

      adminMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              if (body.isNotEmpty) ...[
                if (title.isNotEmpty) const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    // ✅ معالجة الضغط على الإشعار أثناء تشغيل التطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // حفظ الإشعار في القائمة أيضاً
      NotificationService.addFromRemoteMessage(message);

      if (message.data.containsKey('order_id')) {
        final int? orderId = int.tryParse(message.data['order_id'].toString());

        if (orderId != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(orderId: orderId),
            ),
          );
        }
      }
    });
  } else {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: adminMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Smile Lab Admin',
      locale: localeProvider.locale ?? const Locale('ar'),
      supportedLocales: LocaleProvider.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
