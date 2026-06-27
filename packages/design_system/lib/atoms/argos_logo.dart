import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Marca ARGOS — anillo teal con punto dorado + wordmark Garamond.
/// Ref: ARGOS Design System · header.
class ArgosLogo extends StatelessWidget {
  const ArgosLogo({
    super.key,
    this.showWordmark = true,
    this.size = 38,
    this.color = CustomColors.primary,
    this.accent = CustomColors.secondary,
  });

  /// Muestra el texto "ARGOS" junto al símbolo.
  final bool showWordmark;
  final double size;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.26,
        height: size * 0.26,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 14),
        Text(
          'ARGOS',
          style: CustomTypography.garamond(
            fontSize: size * 0.9,
            fontWeight: FontWeight.w600,
            color: color,
          ).copyWith(letterSpacing: 6),
        ),
      ],
    );
  }
}
