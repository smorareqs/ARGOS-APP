import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Campo de texto sobre superficies teal — vidrio translúcido claro.
/// Pensado para el login oscuro de ARGOS.
/// Ref: ARGOS App · Frame 01 · Inicio de sesión.
class DarkTextField extends StatelessWidget {
  const DarkTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
  });

  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final white = Colors.white;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      cursorColor: white,
      style: CustomTypography.verdana(fontSize: 15, color: white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: CustomTypography.verdana(
          fontSize: 15,
          color: white.withValues(alpha: 0.4),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: white.withValues(alpha: 0.45))
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: white.withValues(alpha: 0.07),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: _border(white.withValues(alpha: 0.16)),
        enabledBorder: _border(white.withValues(alpha: 0.16)),
        focusedBorder: _border(white.withValues(alpha: 0.45), width: 1.4),
        errorStyle: CustomTypography.verdana(
          fontSize: 11,
          color: const Color(0xFFE3A99A),
        ),
        errorBorder: _border(const Color(0xFFC97A6E)),
        focusedErrorBorder: _border(const Color(0xFFC97A6E), width: 1.4),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(CustomDimensions.radiusField + 2),
        borderSide: BorderSide(color: color, width: width),
      );
}
