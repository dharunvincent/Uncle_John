import 'package:flutter/material.dart';

class AppColors {
  static const primaryOrange = Color(0xFFD4842A);
  static const darkBrown = Color(0xFF3E2723);
  static const warmBrown = Color(0xFF5D4037);
  static const lightOrange = Color(0xFFFFF3E0);
  static const cream = Color(0xFFFFF8F0);
  static const white = Color(0xFFFFFFFF);

  static const safe = Color(0xFF4CAF50);
  static const moderate = Color(0xFFFFC107);
  static const highRisk = Color(0xFFFF9800);
  static const cancerLinked = Color(0xFFE53935);
  static const unknown = Color(0xFF9E9E9E);

  static const safeBg = Color(0xFFE8F5E9);
  static const moderateBg = Color(0xFFFFF8E1);
  static const highRiskBg = Color(0xFFFFF3E0);
  static const cancerLinkedBg = Color(0xFFFFEBEE);
  static const unknownBg = Color(0xFFF5F5F5);

  static const darkBg = Color(0xFF1A1A1A);
  static const darkCard = Color(0xFF2C2C2C);
  static const darkSurface = Color(0xFF242424);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryOrange,
      secondary: AppColors.warmBrown,
      surface: AppColors.darkCard,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryOrange,
        side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}