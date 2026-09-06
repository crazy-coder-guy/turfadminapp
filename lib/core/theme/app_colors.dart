import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand Palette: #092328 (Dark Deep Emerald/Midnight), #12544F (Forest Pine), #2A835F (Vibrant Turf Green), #8BBB92 (Soft Sage/Mint Accent)
  static const Color primary = Color(0xFF2A835F);
  static const Color primaryDark = Color(0xFF12544F);
  static const Color secondary = Color(0xFF092328);
  static const Color tertiary = Color(0xFFEAF4EE);

  static const Color accent = Color(0xFF8BBB92);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF092328);
  static const Color textSecondary = Color(0xFF4A6360);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE2EBE5);

  static const Color success = Color(0xFF2A835F);
  static const Color warning = Color(0xFFF79009);
  static const Color error = Color(0xFFF04438);

  static const Color successTint = Color(0xFFEAF4EE);
  static const Color warningTint = Color(0xFFFFFAEB);
  static const Color errorTint = Color(0xFFFEF3F2);
  static const Color primaryTint = Color(0xFFEAF4EE);
  static const Color neutralTint = Color(0xFFF4F8F5);
}
