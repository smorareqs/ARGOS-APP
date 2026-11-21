import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Botón destructivo ARGOS — rojo sólido. Solo para confirmar acciones que
/// cierran sesiones, cancelan o eliminan.
/// Ref: ux-ui.md §3.5.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.error,
        foregroundColor: Colors.white,
        disabledBackgroundColor: CustomColors.disabled,
        minimumSize: const Size(0, CustomDimensions.buttonHeightSm),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
        ),
        textStyle: CustomTypography.button.copyWith(fontSize: 13),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
