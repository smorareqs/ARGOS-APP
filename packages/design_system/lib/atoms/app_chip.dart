import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Chip de acción — píldora dorada compacta (p. ej. "Asignar").
/// Ref: ARGOS Design System · 03 · Botones (chip).
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomColors.secondary,
      borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: CustomTypography.verdana(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: CustomColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
