import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Pestaña individual de la barra de navegación inferior — icono + etiqueta.
/// Ref: ARGOS App · bottom tab bar del Itinerario.
class NavTabItem extends StatelessWidget {
  const NavTabItem({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.badge = 0,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;

  /// Contador sobre el icono (avisos sin leer). 0 = sin insignia.
  final int badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? CustomColors.primary : CustomColors.textMuted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: badge > 0 ? '$badge sin leer' : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 23, color: color),
                  if (badge > 0)
                    Positioned(
                      top: -4,
                      right: -9,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 17),
                        height: 17,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: CustomColors.secondary,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: CustomColors.surface, width: 2),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: CustomTypography.verdana(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: CustomColors.onSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: CustomTypography.verdana(
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
