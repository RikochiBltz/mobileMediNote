import 'package:flutter/material.dart';

class AppDesign {
  static const Color green = Color(0xFF27AE60);
  static const Color greenLight = Color(0xFF52BE80);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkNavItem = Color(0xFF2C2C2C);
  static const Color lightTextPrimary = Color(0xFF2C3E50);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  static Color surface(bool isDarkMode) {
    return isDarkMode ? darkSurface : Colors.white;
  }

  static Color textPrimary(bool isDarkMode) {
    return isDarkMode ? Colors.white : lightTextPrimary;
  }

  static Color textSecondary(bool isDarkMode) {
    return isDarkMode ? darkTextSecondary : lightTextSecondary;
  }

  static Color navInactive(bool isDarkMode) {
    return isDarkMode ? darkTextSecondary : lightTextSecondary;
  }

  static Color subtleBorder(bool isDarkMode) {
    return isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);
  }

  static Color cardBorder(bool isDarkMode) {
    return isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);
  }

  static List<Color> pageGradient(bool isDarkMode) {
    return isDarkMode
        ? [green.withOpacity(0.05), darkBackground]
        : [green.withOpacity(0.05), Colors.white];
  }
}
