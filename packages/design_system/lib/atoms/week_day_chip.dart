import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Día individual de la tira de semana — inicial + número de día.
/// Ref: ARGOS App · tira de semana del Itinerario.
class WeekDayChip extends StatelessWidget {
  const WeekDayChip({
    super.key,
    required this.weekday,
    required this.day,
    this.selected = false,
    this.muted = false,
    this.onTap,
  });

  /// Inicial del día (D, L, M, M, J, V, S).
  final String weekday;

  /// Número del día del mes.
  final String day;

  /// Día activo — fondo teal sólido, texto blanco.
  final bool selected;

  /// Fuera del rango relevante (fin de semana / otro mes) — atenuado.
  final bool muted;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color labelColor;
    final Color dayColor;

    if (selected) {
      labelColor = Colors.white.withValues(alpha: 0.6);
      dayColor = Colors.white;
    } else if (muted) {
      labelColor = CustomColors.textMuted;
      dayColor = CustomColors.textMuted;
    } else {
      labelColor = CustomColors.textMuted;
      dayColor = CustomColors.primary;
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? CustomColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekday,
                style: CustomTypography.verdana(fontSize: 10, color: labelColor),
              ),
              const SizedBox(height: 6),
              Text(
                day,
                style: CustomTypography.verdana(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: dayColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
