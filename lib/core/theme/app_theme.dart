import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CustomColors.primary,
        primary: CustomColors.primary,
        secondary: CustomColors.secondary,
        surface: CustomColors.surface,
        error: CustomColors.error,
      ),
      scaffoldBackgroundColor: CustomColors.background,
      textTheme: CustomTypography.textTheme.apply(
        bodyColor: CustomColors.onBackground,
        displayColor: CustomColors.onBackground,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CustomColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CustomDimensions.radiusMd),
          borderSide: const BorderSide(color: CustomColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CustomDimensions.radiusMd),
          borderSide: const BorderSide(color: CustomColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CustomDimensions.radiusMd),
          borderSide: const BorderSide(color: CustomColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CustomDimensions.spacingMd,
          vertical: CustomDimensions.spacingSm,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: CustomColors.primary,
        foregroundColor: CustomColors.onPrimary,
        elevation: 0,
        titleTextStyle: CustomTypography.titleMedium.copyWith(
          color: CustomColors.onPrimary,
        ),
      ),
    );
  }
}
