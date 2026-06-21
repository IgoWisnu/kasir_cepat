import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFFD32F2F);      // Elegant Red
  static const Color primaryLight = Color(0xFFFFEBEE); // Soft Red tint
  static const Color primaryDark = Color(0xFFB71C1C);  // Deep Red
  static const Color accent = Color(0xFFFF5252);       // Bright Red

  // Neutral colors
  static const Color background = Color(0xFFF8F9FA);   // Ultra light grey
  static const Color surface = Color(0xFFFFFFFF);      // White for cards
  static const Color border = Color(0xFFECEFF1);       // Light border line

  // Text colors
  static const Color textPrimary = Color(0xFF212121);    // Soft Black
  static const Color textSecondary = Color(0xFF666666);  // Cool Grey
  static const Color textLight = Color(0xFF9E9E9E);      // Muted Grey

  // Semantic colors
  static const Color success = Color(0xFF2E7D32);      // Emerald Green
  static const Color warning = Color(0xFFF57C00);      // Warning Amber
  static const Color error = Color(0xFFD32F2F);        // Error Red
  static const Color info = Color(0xFF1976D2);         // Info Blue

  // Shadow colors
  static const Color shadow = Color(0x0F000000);       // Ultra soft shadow for floating cards
}
