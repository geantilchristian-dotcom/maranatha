import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Manrope';
  static const TextStyle heroTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 25,
    height: 1.06,
    fontWeight: FontWeight.w800,
    color: AppColors.navy,
    letterSpacing: -0.7,
  );
  static const TextStyle pageTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w800,
    color: AppColors.navy,
  );
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const TextStyle navigation = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 1.15,
    fontWeight: FontWeight.w600,
  );
}
