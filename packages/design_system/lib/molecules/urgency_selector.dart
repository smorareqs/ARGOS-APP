import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Urgencia de una incidencia (B12), con su color y una línea de ayuda.
enum Urgency {
  low('low', 'Baja', 'Puede esperar', CustomColors.success, CustomColors.successSoft),
  medium('medium', 'Media', 'Esta semana', CustomColors.tealMuted, CustomColors.infoSoft),
  high('high', 'Alta', 'Hoy mismo', CustomColors.warning, CustomColors.warningSoft),
  critical('critical', 'Crítica', 'Riesgo o sin servicio', CustomColors.error, CustomColors.errorSoft);

  const Urgency(this.wire, this.label, this.hint, this.color, this.soft);

  /// Valor de la API.
  final String wire;
  final String label;
  final String hint;
  final Color color;
  final Color soft;

  static Urgency parse(String? value) =>
      Urgency.values.firstWhere((u) => u.wire == value, orElse: () => Urgency.medium);
}

/// Cuatro opciones de urgencia en rejilla de 2×2.
class UrgencySelector extends StatelessWidget {
  const UrgencySelector({super.key, required this.value, required this.onChanged});

  final Urgency value;
  final ValueChanged<Urgency> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(Urgency u) {
      final active = u == value;
      return Expanded(
        child: Semantics(
          selected: active,
          button: true,
          child: GestureDetector(
            onTap: () => onChanged(u),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: active ? u.soft : CustomColors.surface,
                borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
                border: Border.all(
                  color: active ? u.color : CustomColors.borderField,
                  width: active ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: u.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.label,
                          style: CustomTypography.verdana(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: active ? u.color : CustomColors.textPrimary,
                          ),
                        ),
                        Text(
                          u.hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomTypography.verdana(
                            fontSize: 11,
                            color: CustomColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [option(Urgency.low), const SizedBox(width: 10), option(Urgency.medium)]),
        const SizedBox(height: 10),
        Row(children: [option(Urgency.high), const SizedBox(width: 10), option(Urgency.critical)]),
      ],
    );
  }
}
