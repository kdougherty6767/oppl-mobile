import 'package:flutter/material.dart';

class AppColors {
  // Dark palette inspired by web app (adjust to match exactly later)
  static const Color darkBg = Color(0xFF0F0A1E);
  static const Color darkCard = Color(0xFF1B1330);
  static const Color primary = Color(0xFF7C3AED); // vivid purple
  static const Color accent = Color(0xFF22D3EE); // cyan accent
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCBD5E1);

  // Light palette placeholder
  static const Color lightBg = Colors.white;
  static const Color lightCard = Color(0xFFF3F4F6);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      background: AppColors.darkBg,
      surface: AppColors.darkCard,
    ),
    cardColor: AppColors.darkCard,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
    ),
  );
}

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      background: AppColors.lightBg,
      surface: AppColors.lightCard,
    ),
    cardColor: AppColors.lightCard,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
      bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
    ),
  );
}
