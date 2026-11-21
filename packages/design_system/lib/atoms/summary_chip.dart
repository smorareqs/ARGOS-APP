import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Métrica de resumen sobre el header teal — número Garamond grande + etiqueta.
/// Diseñado para mostrarse sobre [CustomColors.primary].
/// Ref: ARGOS App · header del Itinerario ("Limpiezas hoy", "En progreso"…).
class SummaryChip extends StatelessWidget {
  const SummaryChip({
    super.key,
    required this.value,
    required this.label,
    this.suffix,
    this.valueColor = Colors.white,
  });

  /// Número principal (p. ej. "4", "1").
  final String value;

  /// Etiqueta inferior (p. ej. "Limpiezas hoy").
  final String label;

  /// Sufijo atenuado opcional (p. ej. "/4" en "1/4").
  final String? suffix;

  /// Color del número — blanco por defecto, dorado para destacar.
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(CustomDimensions.radiusField + 2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              text: value,
              style: CustomTypography.garamond(
                fontSize: 26,
                color: valueColor,
                height: 1.0,
              ),
              children: suffix != null
                  ? [
                      TextSpan(
                        text: suffix,
                        style: CustomTypography.garamond(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: CustomTypography.verdana(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
