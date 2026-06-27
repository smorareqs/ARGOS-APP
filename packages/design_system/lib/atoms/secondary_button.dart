import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

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
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: CustomColors.primary,
        side: const BorderSide(color: CustomColors.primary),
        minimumSize: const Size(0, CustomDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CustomDimensions.radiusMd),
        ),
        textStyle: CustomTypography.labelLarge,
      ),
      child: Text(label),
    );

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
