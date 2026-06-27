import 'package:design_system/atoms/app_text_field.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Etiqueta en mayúsculas + [AppTextField].
/// Ref: ARGOS Design System · 03 · "Correo electrónico" + campo.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.field,
  });

  /// Texto de la etiqueta (se muestra en MAYÚSCULAS).
  final String label;

  /// El campo asociado, normalmente un [AppTextField].
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: CustomTypography.label),
        const SizedBox(height: CustomDimensions.spacingSm),
        field,
      ],
    );
  }
}
