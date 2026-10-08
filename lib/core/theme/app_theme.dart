import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF14C8B0); // اللون الفيروزي الرئيسي
  static const Color primaryDark = Color(0xFF0EA28E);
  static const Color background = Color(0xFFF4F8F7); // خلفية فاتحة وناعمة
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color accentMint = Color(0xFFE6F8F5);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: 'Cairo', // أو أي خط تفضله
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.cardBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
