import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:flutter/material.dart';

/// Barra de progreso ARGOS — pista clara con relleno dorado.
/// Ref: ARGOS App · tarjeta "en progreso" (checklist 5/12).
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.trackColor = CustomColors.track,
    this.fillColor = CustomColors.secondary,
  });

  /// Progreso en el rango 0.0 – 1.0.
  final double value;
  final double height;
  final Color trackColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              ColoredBox(
                color: trackColor,
                child: const SizedBox.expand(),
              ),
              Container(
                width: constraints.maxWidth * clamped,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
