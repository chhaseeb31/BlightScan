import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors - BlightScan design
  static const Color primary = Color(0xFF1FA971);
  static const Color primaryDark = Color(0xFF168555);
  static const Color primaryLight = Color(0xFF4DD9A3);
  static const Color primarySurface = Color(0xFFE6FBF3);

  // Background Colors - Light
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color backgroundGreen = Color(0xFF1FA971);

  // Text Colors - Light
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF00C17C);

  // Surface Colors - Light
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color surfaceOverlay = Color(0x80000000);

  // Border Colors - Light
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderFocused = Color(0xFF00C17C);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Disease Severity
  static const Color severityHigh = Color(0xFFEF4444);
  static const Color severityMedium = Color(0xFFF59E0B);
  static const Color severityLow = Color(0xFF22C55E);

  // Card Colors
  static const Color cardShadow = Color(0x1A000000);

  // Alert indicator dot
  static const Color notificationDot = Color(0xFF00C17C);

  // Icon Colors
  static const Color iconDefault = Color(0xFF6B7280);
  static const Color iconActive = Color(0xFF00C17C);

  // Tag / Category Colors
  static const Color tagSucculents = Color(0xFF22C55E);
  static const Color tagFoliage = Color(0xFF00C17C);
  static const Color tagFlowering = Color(0xFFF59E0B);

  // Bottom Nav
  static const Color bottomNavActive = Color(0xFF00C17C);
  static const Color bottomNavInactive = Color(0xFF9CA3AF);
  static const Color bottomNavBackground = Color(0xFFFFFFFF);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C17C), Color(0xFF00A567)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF00C17C), Color(0xFF008F5B)],
  );

  // Scan overlay
  static const Color scanOverlay = Color(0x80000000);
  static const Color scanFrame = Color(0xFF00C17C);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkBackgroundSecondary = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF808080);
  static const Color darkTextHint = Color(0xFF808080);
  static const Color darkBorder = Color(0xFF3D3D3D);
  static const Color darkBottomNavBackground = Color(0xFF1E1E1E);
  static const Color darkBottomNavInactive = Color(0xFF808080);
}

class AdaptiveColors {
  AdaptiveColors._();

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBackground
        : AppColors.background;
  }

  static Color backgroundSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBackgroundSecondary
        : AppColors.backgroundSecondary;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurface
        : AppColors.surface;
  }

  static Color surfaceVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
  }

  static Color textHint(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextHint
        : AppColors.textHint;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorder
        : AppColors.border;
  }

  static Color bottomNavBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBottomNavBackground
        : AppColors.bottomNavBackground;
  }

  static Color bottomNavInactive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBottomNavInactive
        : AppColors.bottomNavInactive;
  }
}
