import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.andika(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle display({Color color = AppColors.textPrimary}) =>
      _base(size: 30, weight: FontWeight.w700, color: color, height: 1.2);

  static TextStyle appHeader({Color color = AppColors.textPrimary}) =>
      _base(size: 22, weight: FontWeight.w700, color: color, height: 1.3);

  static TextStyle sectionHeader({Color color = AppColors.textPrimary}) =>
      _base(size: 18, weight: FontWeight.w600, color: color, height: 1.3);

  static TextStyle cardTitle({Color color = AppColors.textPrimary}) =>
      _base(size: 16, weight: FontWeight.w600, color: color, height: 1.4);

  static TextStyle body({Color color = AppColors.textPrimary}) =>
      _base(size: 14, weight: FontWeight.w400, color: color, height: 1.5);

  static TextStyle bodySmall({Color color = AppColors.textSecondary}) =>
      _base(size: 13, weight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle label({Color color = AppColors.textPrimary}) =>
      _base(size: 13, weight: FontWeight.w500, color: color, height: 1.3);

  static TextStyle caption({Color color = AppColors.textSecondary}) =>
      _base(size: 12, weight: FontWeight.w400, color: color, height: 1.3);

  static TextStyle button({Color color = AppColors.textOnPrimary}) =>
      _base(size: 14, weight: FontWeight.w600, color: color, height: 1.2);

  static TextStyle navigation({Color color = AppColors.textSecondary}) =>
      _base(size: 11, weight: FontWeight.w500, color: color, height: 1.2);
}
