import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_shadows.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// CTA principal de ARGOS — fondo dorado con glow de elevación.
/// Ref: ARGOS Design System · 03 · Botones (primario).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;

  /// Icono opcional al final (p. ej. flecha en "Iniciar sesión →").
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;

    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
        boxShadow: enabled ? CustomShadows.cta : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: CustomColors.secondary,
          foregroundColor: CustomColors.onSecondary,
          disabledBackgroundColor: CustomColors.disabled,
          minimumSize: const Size(0, CustomDimensions.buttonHeight),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
          ),
          textStyle: CustomTypography.button,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CustomColors.onSecondary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: CustomDimensions.spacingSm),
                    Icon(trailingIcon, size: CustomDimensions.iconSizeSm),
                  ],
                ],
              ),
      ),
    );

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
