// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      fontFamily: 'SFProDisplay',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimaryDark, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
      ),
      dividerColor: AppColors.borderDark,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      ),
      fontFamily: 'SFProDisplay',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
      ),
      dividerColor: AppColors.borderLight,
    );
  }
}