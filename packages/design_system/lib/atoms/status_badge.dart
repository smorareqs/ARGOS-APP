import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Variantes semánticas de estado en ARGOS.
enum StatusBadgeVariant { inProgress, operative, incident, pending }

/// Insignia de estado — píldora con punto de color.
/// Ref: ARGOS Design System · 03 · Insignias de estado.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.pending,
  });

  final String label;
  final StatusBadgeVariant variant;

  // (fondo, punto, texto) por variante — valores exactos del spec.
  _BadgeColors get _colors => switch (variant) {
    StatusBadgeVariant.inProgress => const _BadgeColors(
      Color(0x24C5873C), // rgba(197,135,60,0.14)
      Color(0xFFC5873C),
      Color(0xFF9A6722),
    ),
    StatusBadgeVariant.operative => const _BadgeColors(
      Color(0x14003841), // rgba(0,56,65,0.08)
      Color(0xFF5A8A6B),
      Color(0xFF003841),
    ),
    StatusBadgeVariant.incident => const _BadgeColors(
      Color(0x1A892F26), // rgba(137,47,38,0.10)
      Color(0xFF892F26),
      Color(0xFF892F26),
    ),
    StatusBadgeVariant.pending => const _BadgeColors(
      Color(0xFFF0EDE4),
      Color(0xFFA8A89C),
      Color(0xFF7D7D72),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: CustomTypography.verdana(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: c.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeColors {
  const _BadgeColors(this.background, this.dot, this.text);
  final Color background;
  final Color dot;
  final Color text;
}
