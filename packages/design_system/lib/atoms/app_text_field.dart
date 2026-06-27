import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Campo de texto ARGOS — superficie blanca, borde de campo, radio 12px.
/// Ref: ARGOS Design System · 03 · Campos de formulario.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      style: CustomTypography.verdana(
        fontSize: 15,
        color: CustomColors.primary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: CustomTypography.verdana(
          fontSize: 15,
          color: CustomColors.textMuted,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: CustomColors.disabled)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: CustomColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CustomDimensions.spacingMd,
          vertical: CustomDimensions.spacingMd,
        ),
        border: _border(CustomColors.borderField),
        enabledBorder: _border(CustomColors.borderField),
        focusedBorder: _border(CustomColors.secondary, width: 1.6),
        errorBorder: _border(CustomColors.error),
        focusedErrorBorder: _border(CustomColors.error, width: 1.6),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
        borderSide: BorderSide(color: color, width: width),
      );
}
