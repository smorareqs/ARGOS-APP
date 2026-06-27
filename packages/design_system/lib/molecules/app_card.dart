import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_shadows.dart';
import 'package:flutter/material.dart';

/// Tarjeta base ARGOS — superficie blanca, radio 18px, borde de tarjeta.
/// Ref: ARGOS Design System · Tarjeta — 18px.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CustomDimensions.spacingLg),
    this.elevated = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Aplica la sombra de elevación del spec.
  final bool elevated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: CustomColors.surface,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
        border: Border.all(color: CustomColors.border),
        boxShadow: elevated ? CustomShadows.card : null,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
      child: content,
    );
  }
}
