import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide:
              const BorderSide(color: AppColors.borderFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textHint,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomNavBackground,
        selectedItemColor: AppColors.bottomNavActive,
        unselectedItemColor: AppColors.bottomNavInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        selectedColor: AppColors.primary,
        labelStyle:
            GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      extensions: const [
        AppColorsExtension(
          primary: AppColors.primary,
          primaryDark: AppColors.primaryDark,
          primaryLight: AppColors.primaryLight,
          primarySurface: AppColors.primarySurface,
          success: AppColors.success,
          warning: AppColors.warning,
          info: AppColors.info,
          severityHigh: AppColors.severityHigh,
          severityMedium: AppColors.severityMedium,
          severityLow: AppColors.severityLow,
          cardShadow: AppColors.cardShadow,
          notificationDot: AppColors.notificationDot,
          iconDefault: AppColors.iconDefault,
          iconActive: AppColors.iconActive,
          tagSucculents: AppColors.tagSucculents,
          tagFoliage: AppColors.tagFoliage,
          tagFlowering: AppColors.tagFlowering,
          primaryGradient: AppColors.primaryGradient,
          splashGradient: AppColors.splashGradient,
          scanOverlay: AppColors.scanOverlay,
          scanFrame: AppColors.scanFrame,
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.primaryLight,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 24,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkBackgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.darkTextHint,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBottomNavBackground,
        selectedItemColor: AppColors.bottomNavActive,
        unselectedItemColor: AppColors.darkBottomNavInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle:
            GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      extensions: const [
        AppColorsExtension(
          primary: AppColors.primary,
          primaryDark: AppColors.primaryDark,
          primaryLight: AppColors.primaryLight,
          primarySurface: AppColors.primarySurface,
          success: AppColors.success,
          warning: AppColors.warning,
          info: AppColors.info,
          severityHigh: AppColors.severityHigh,
          severityMedium: AppColors.severityMedium,
          severityLow: AppColors.severityLow,
          cardShadow: AppColors.cardShadow,
          notificationDot: AppColors.notificationDot,
          iconDefault: AppColors.iconDefault,
          iconActive: AppColors.iconActive,
          tagSucculents: AppColors.tagSucculents,
          tagFoliage: AppColors.tagFoliage,
          tagFlowering: AppColors.tagFlowering,
          primaryGradient: AppColors.primaryGradient,
          splashGradient: AppColors.splashGradient,
          scanOverlay: AppColors.scanOverlay,
          scanFrame: AppColors.scanFrame,
        ),
      ],
    );
  }
}

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primarySurface;
  final Color success;
  final Color warning;
  final Color info;
  final Color severityHigh;
  final Color severityMedium;
  final Color severityLow;
  final Color cardShadow;
  final Color notificationDot;
  final Color iconDefault;
  final Color iconActive;
  final Color tagSucculents;
  final Color tagFoliage;
  final Color tagFlowering;
  final LinearGradient primaryGradient;
  final LinearGradient splashGradient;
  final Color scanOverlay;
  final Color scanFrame;

  const AppColorsExtension({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primarySurface,
    required this.success,
    required this.warning,
    required this.info,
    required this.severityHigh,
    required this.severityMedium,
    required this.severityLow,
    required this.cardShadow,
    required this.notificationDot,
    required this.iconDefault,
    required this.iconActive,
    required this.tagSucculents,
    required this.tagFoliage,
    required this.tagFlowering,
    required this.primaryGradient,
    required this.splashGradient,
    required this.scanOverlay,
    required this.scanFrame,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? primarySurface,
    Color? success,
    Color? warning,
    Color? info,
    Color? severityHigh,
    Color? severityMedium,
    Color? severityLow,
    Color? cardShadow,
    Color? notificationDot,
    Color? iconDefault,
    Color? iconActive,
    Color? tagSucculents,
    Color? tagFoliage,
    Color? tagFlowering,
    LinearGradient? primaryGradient,
    LinearGradient? splashGradient,
    Color? scanOverlay,
    Color? scanFrame,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      primarySurface: primarySurface ?? this.primarySurface,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      severityHigh: severityHigh ?? this.severityHigh,
      severityMedium: severityMedium ?? this.severityMedium,
      severityLow: severityLow ?? this.severityLow,
      cardShadow: cardShadow ?? this.cardShadow,
      notificationDot: notificationDot ?? this.notificationDot,
      iconDefault: iconDefault ?? this.iconDefault,
      iconActive: iconActive ?? this.iconActive,
      tagSucculents: tagSucculents ?? this.tagSucculents,
      tagFoliage: tagFoliage ?? this.tagFoliage,
      tagFlowering: tagFlowering ?? this.tagFlowering,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      splashGradient: splashGradient ?? this.splashGradient,
      scanOverlay: scanOverlay ?? this.scanOverlay,
      scanFrame: scanFrame ?? this.scanFrame,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return this;
  }
}
