import 'package:flutter/material.dart';

/// Tokens de elevación ARGOS.
/// Ref: ARGOS Design System · 03 · Sombra de elevación.
abstract final class CustomShadows {
  /// Elevación de tarjeta / superficie flotante.
  /// `0 8px 20px rgba(0,56,65,.10)`
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1A003841), // rgba(0,56,65,0.10)
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// Glow del CTA dorado. `0 8px 20px rgba(197,135,60,.28)`
  static const List<BoxShadow> cta = [
    BoxShadow(
      color: Color(0x47C5873C), // rgba(197,135,60,0.28)
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
