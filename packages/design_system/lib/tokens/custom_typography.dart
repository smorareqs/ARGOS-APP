import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class CustomTypography {
  static TextTheme textTheme = GoogleFonts.poppinsTextTheme();

  static TextStyle get headlineLarge => textTheme.headlineLarge!.copyWith(
        fontWeight: FontWeight.w700,
      );

  static TextStyle get titleMedium => textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyMedium => textTheme.bodyMedium!;

  static TextStyle get labelLarge => textTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w600,
      );
}
