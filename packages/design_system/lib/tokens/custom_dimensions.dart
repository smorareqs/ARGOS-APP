/// Tokens de geometría ARGOS — espaciado, radios, alturas.
/// Ref: ARGOS Design System · 03 · Tokens de geometría.
abstract final class CustomDimensions {
  // ── Espaciado ──────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // ── Radios ─────────────────────────────────────────────
  /// Campo — inputs y botones.
  static const double radiusField = 12;

  /// Tarjeta — paneles y contenedores principales.
  static const double radiusCard = 18;

  /// Píldora — insignias, chips, avatares.
  static const double radiusPill = 9999;

  // Alias legacy / convenientes.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 18;

  // ── Alturas ────────────────────────────────────────────
  /// Botón primario / campo (CTA principal).
  static const double buttonHeight = 52;

  /// Botón secundario / terciario.
  static const double buttonHeightSm = 46;

  static const double fieldHeight = 52;

  // ── Iconografía ────────────────────────────────────────
  static const double iconSize = 24;
  static const double iconSizeSm = 18;
}
