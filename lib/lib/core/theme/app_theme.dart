import 'package:flutter/material.dart';

class AppColors {
  // Teal palette
  static const primary      = Color(0xFF0D6E8A);  // main teal
  static const primaryDark  = Color(0xFF1A4A5A);  // dark teal (header start)
  static const accent       = Color(0xFF0D8A6E);  // teal-green (positive/completed)
  static const background   = Color(0xFFF0F4F8);  // page background
  static const cardBg       = Colors.white;
  static const neonGreen    = Color(0xFFBEFF5A);  // tennis ball

  // Semantic
  static const debt         = Color(0xFFC62828);
  static const debtLight    = Color(0xFFFFEBEE);
  static const makeup       = Color(0xFFFB8C00);
  static const upcoming     = Color(0xFF1565C0);
  static const cancelled    = Color(0xFFE53935);
  static const weather      = Color(0xFF5E35B1);
  static const holiday      = Color(0xFF6A1B9A);
  static const rescheduled  = Color(0xFFEF6C00);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Vazirmatn',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.cardBg,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withAlpha(30),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
              fontFamily: 'Vazirmatn', fontSize: 10,
              fontWeight: FontWeight.w600, color: AppColors.primary);
        }
        return const TextStyle(
            fontFamily: 'Vazirmatn', fontSize: 10, color: Colors.grey);
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(
            fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      labelStyle: const TextStyle(color: Colors.grey, fontFamily: 'Vazirmatn'),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
  );
}
