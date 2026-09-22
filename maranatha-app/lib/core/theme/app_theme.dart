import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTypography.pageTitle,
        headlineMedium: AppTypography.sectionTitle,
        titleMedium: AppTypography.cardTitle,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodySecondary,
        labelLarge: AppTypography.label,
      ),
      dividerColor: AppColors.divider,
      splashColor: AppColors.primarySoft,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
