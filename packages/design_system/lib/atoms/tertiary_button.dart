import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Botón terciario de ARGOS — superficie blanca con borde de campo.
/// Ref: ARGOS Design System · 03 · Botones (terciario).
class TertiaryButton extends StatelessWidget {
  const TertiaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: CustomColors.surface,
        foregroundColor: CustomColors.primary,
        side: const BorderSide(color: CustomColors.borderField),
        minimumSize: const Size(0, CustomDimensions.buttonHeightSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
        ),
        textStyle: CustomTypography.button.copyWith(
          fontSize: 13,
          color: CustomColors.primary,
        ),
      ),
      child: Text(label),
    );

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
