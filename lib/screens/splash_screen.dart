import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/locale_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // إعداد حركة ظهور الشعار بشكل ناعم
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
    _checkNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkNextScreen() async {
    // انتظار ثانيتين لإكمال الحركة والعرض
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 1. التحقق إن كانت هذه المرة الأولى لتشغيل التطبيق
    bool isFirstTime = await StorageService.isFirstTime();
    if (isFirstTime) {
      _navigateTo(const OnboardingScreen());
      return;
    }

    // 2. فحص وجود التوكن المخزن سلفاً
    String? token = await StorageService.getToken();

    if (!mounted) return;

    // 3. التوجيه المباشر للهوم في حال وجود توكن، أو للـ Login في حال عدم وجوده
    if (token != null && token.isNotEmpty) {
      // ✅ مزامنة اللغة مع السيرفر بعد تسجيل دخول سابق
      // (لضمان أن السيرفر على علم بأحدث لغة اختارها المستخدم)
      await _syncLocaleWithServer();

      if (!mounted) return;
      _navigateTo(const HomeScreen());
    } else {
      _navigateTo(const LoginScreen());
    }
  }

  /// ✅ مزامنة اللغة الحالية مع السيرفر
  Future<void> _syncLocaleWithServer() async {
    try {
      final localeProvider = context.read<LocaleProvider>();
      await localeProvider.syncCurrentLocale();
    } catch (e) {}
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // خلفية مع تدرج دوائر ناعمة لمظهر 3D
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(20),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(15),
              ),
            ),
          ),

          // الشعار المائل والرسوم المحركة في المنتصف
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // كارت الشعار التجسيمي Soft 3D
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.accentMint,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(40),
                            blurRadius: 35,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.medical_services_rounded,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // اسم التطبيق (علامة تجارية تبقى ثابتة)
                    const Text(
                      'Lab Smile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // الوصف الفرعي المترجم
                    Text(
                      loc?.translate('splash_subtitle') ??
                          'إدارة طلبات معمل الأسنان بسهولة',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // مؤشر التحميل في الأسفل
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary.withAlpha(180),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
