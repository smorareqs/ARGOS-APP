import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Botón secundario de ARGOS — teal sólido.
/// Ref: ARGOS Design System · 03 · Botones (secundario).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
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
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.primary,
        foregroundColor: CustomColors.onPrimary,
        disabledBackgroundColor: CustomColors.disabled,
        minimumSize: const Size(0, CustomDimensions.buttonHeightSm),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
        ),
        textStyle: CustomTypography.button.copyWith(fontSize: 13),
      ),
      child: Text(label),
    );

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
