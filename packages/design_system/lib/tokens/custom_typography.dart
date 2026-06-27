import 'package:design_system/tokens/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografía ARGOS.
/// - **EB Garamond** (serif) → display, títulos, saludos, números destacados.
/// - **Verdana** (sans, sistema) → cuerpo, etiquetas, datos, formularios, UI.
/// Ref: ARGOS Design System · 02 · Tipografía.
abstract final class CustomTypography {
  /// Familia de interfaz. Verdana es fuente de sistema (no GoogleFonts).
  static const String _sansFamily = 'Verdana';
  static const List<String> _sansFallback = ['Geneva', 'sans-serif'];

  // ── Builders base ──────────────────────────────────────
  static TextStyle garamond({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color color = const Color(0xFF003841),
    double? height,
    FontStyle? fontStyle,
  }) => GoogleFonts.ebGaramond(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    fontStyle: fontStyle,
  );

  static TextStyle verdana({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF5A5A52),
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: _sansFamily,
    fontFamilyFallback: _sansFallback,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  // ── Escala tipográfica (semántica ARGOS) ───────────────
  /// Display · hero / login. Garamond 600 · 46px.
  static TextStyle get display =>
      garamond(fontSize: 46, height: 1.0);

  /// Título de página (H1). Garamond 600 · 30px.
  static TextStyle get pageTitle =>
      garamond(fontSize: 30, height: 1.1);

  /// Saludo (Buenos días, …). Garamond 600 · 30px.
  static TextStyle get greeting => pageTitle;

  /// Título de tarjeta (H2). Garamond 600 · 17px.
  static TextStyle get cardTitle => garamond(fontSize: 17);

  /// Cuerpo y descripciones. Verdana · 14px.
  static TextStyle get body => verdana(fontSize: 14, height: 1.6);

  /// Dato / valor en tabla. Verdana 700 · 13px.
  static TextStyle get data => verdana(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: CustomColors.primary,
  );

  /// Etiqueta / microcopy. Verdana · 11px · +1px · MAYÚSCULAS.
  static TextStyle get label => verdana(
    fontSize: 11,
    letterSpacing: 1,
    color: CustomColors.textMuted,
  );

  /// Texto de botón. Verdana bold · 14px.
  static TextStyle get button => verdana(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // ── Alias legacy (Material slots) ──────────────────────
  static TextStyle get headlineLarge => display;
  static TextStyle get titleMedium => cardTitle;
  static TextStyle get bodyMedium => body;
  static TextStyle get labelLarge =>
      verdana(fontSize: 14, fontWeight: FontWeight.bold, color: CustomColors.primary);

  /// TextTheme para inyectar en [ThemeData].
  static TextTheme get textTheme => TextTheme(
    displayLarge: display,
    headlineLarge: display,
    headlineMedium: pageTitle,
    titleLarge: pageTitle,
    titleMedium: cardTitle,
    bodyLarge: body,
    bodyMedium: body,
    labelLarge: labelLarge,
    labelSmall: label,
  );
}
