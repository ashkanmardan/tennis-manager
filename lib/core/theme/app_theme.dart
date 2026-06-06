import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2E7D32); // Tennis green
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFFFFD700); // Tennis ball yellow
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Vazirmatn',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          color: surfaceColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Vazirmatn'),
          displayMedium: TextStyle(fontFamily: 'Vazirmatn'),
          displaySmall: TextStyle(fontFamily: 'Vazirmatn'),
          headlineLarge: TextStyle(fontFamily: 'Vazirmatn'),
          headlineMedium: TextStyle(fontFamily: 'Vazirmatn'),
          headlineSmall: TextStyle(fontFamily: 'Vazirmatn'),
          titleLarge: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontFamily: 'Vazirmatn'),
          titleSmall: TextStyle(fontFamily: 'Vazirmatn'),
          bodyLarge: TextStyle(fontFamily: 'Vazirmatn'),
          bodyMedium: TextStyle(fontFamily: 'Vazirmatn'),
          bodySmall: TextStyle(fontFamily: 'Vazirmatn'),
          labelLarge: TextStyle(fontFamily: 'Vazirmatn'),
          labelMedium: TextStyle(fontFamily: 'Vazirmatn'),
          labelSmall: TextStyle(fontFamily: 'Vazirmatn'),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: primaryColor,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          backgroundColor: surfaceColor,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        dividerTheme: const DividerThemeData(
          thickness: 1,
          color: Color(0xFFEEEEEE),
        ),
      );
}
