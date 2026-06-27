import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Encabezado de sección — número + título en mayúsculas + regla horizontal.
/// Ref: ARGOS Design System · "01 · Paleta de color", etc.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.number,
  });

  /// Título de la sección (se muestra en MAYÚSCULAS).
  final String title;

  /// Número opcional de orden, p. ej. "01".
  final String? number;

  @override
  Widget build(BuildContext context) {
    final text = number != null ? '$number · $title' : title;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          text.toUpperCase(),
          style: CustomTypography.verdana(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: CustomColors.textSecondary,
          ).copyWith(letterSpacing: 2),
        ),
        const SizedBox(width: CustomDimensions.spacingMd),
        const Expanded(child: Divider(color: CustomColors.divider, height: 1)),
      ],
    );
  }
}
