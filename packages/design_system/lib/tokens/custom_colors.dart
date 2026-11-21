import 'package:flutter/material.dart';

/// Paleta de color ARGOS — Teal profundo como base, dorado como acento de acción.
/// Ref: ARGOS Design System · 01 · Paleta de color.
abstract final class CustomColors {
  // ── Marca ───────────────────────────────────────────────
  /// Teal profundo · color primario de marca. Fondos, texto, navegación.
  static const Color primary = Color(0xFF003841);

  /// Dorado Peru · acento de acción / CTA. Botones, métricas, estados activos.
  static const Color secondary = Color(0xFFC5873C);

  // ── Tonos de apoyo ─────────────────────────────────────
  /// Teal secundario.
  static const Color tealMuted = Color(0xFF3A6168);

  /// Verde · estado "en vivo" / operativo.
  static const Color success = Color(0xFF5A8A6B);

  /// Rojo · incidencia / error.
  static const Color error = Color(0xFF892F26);

  /// Teal lavado · superficies de mapa.
  static const Color tealWashed = Color(0xFFE6EEEC);

  // ── Neutros cálidos (arena) ────────────────────────────
  /// Lienzo / fondo base.
  static const Color canvas = Color(0xFFE7E4DD);

  /// Fondo de app.
  static const Color background = Color(0xFFF4F1EA);

  /// Superficie suave.
  static const Color surfaceSoft = Color(0xFFFBFAF6);

  /// Tarjeta / superficie elevada.
  static const Color surface = Color(0xFFFFFFFF);

  // ── Texto ──────────────────────────────────────────────
  /// Texto principal (= primary).
  static const Color textPrimary = Color(0xFF003841);

  /// Texto de cuerpo.
  static const Color textBody = Color(0xFF5A5A52);

  /// Texto secundario.
  static const Color textSecondary = Color(0xFF7D7D72);

  /// Texto tenue / etiqueta.
  static const Color textMuted = Color(0xFF9A9A90);

  // ── Bordes y divisores ─────────────────────────────────
  /// Borde de campo (inputs).
  static const Color borderField = Color(0xFFE2DED3);

  /// Borde de tarjeta.
  static const Color border = Color(0xFFEDE9DE);

  /// Divisor sutil.
  static const Color divider = Color(0xFFF0ECE2);

  /// Pista / track (sliders, barras).
  static const Color track = Color(0xFFEFEBE0);

  // ── Sobre color ────────────────────────────────────────
  /// Texto/iconos sobre [primary].
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Texto/iconos sobre [secondary].
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// Texto sobre superficies claras.
  static const Color onSurface = Color(0xFF003841);

  /// Texto sobre fondo (alias de [textPrimary]).
  static const Color onBackground = Color(0xFF003841);

  /// Color de elementos deshabilitados.
  static const Color disabled = Color(0xFFB0B0A6);

  // ── Estados (insignias, avisos) ────────────────────────
  // Ref: ux-ui.md §2.2 · tokens nuevos compartidos con la web.

  /// Texto y borde de advertencia (retraso, vencido, pendiente de acuse).
  static const Color warning = Color(0xFF9A6722);

  /// Fondo de insignia de advertencia.
  static const Color warningSoft = Color(0xFFF6E7D2);

  /// Fondo de insignia de éxito.
  static const Color successSoft = Color(0xFFE3EEE6);

  /// Fondo de insignia de error.
  static const Color errorSoft = Color(0xFFF3E1DE);

  /// Fondo de insignia informativa (= [tealWashed]).
  static const Color infoSoft = Color(0xFFE6EEEC);

  /// Fondo de insignia neutra (= [track]).
  static const Color neutralSoft = Color(0xFFEFEBE0);

  /// Scrim de modales y hojas · rgba(0,56,65,0.55).
  static const Color overlay = Color(0x8C003841);

  /// Barra de estado "sin conexión".
  static const Color offline = Color(0xFF5A5A52);

  // ── Error sobre teal (login y desbloqueo) ──────────────
  /// Texto de error sobre [primary].
  static const Color errorOnDark = Color(0xFFE3A99A);

  /// Borde de campo con error sobre [primary].
  static const Color errorBorderOnDark = Color(0xFFC97A6E);
}
