import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Fila de lista ARGOS — icono, título, subtítulo opcional y chevron o
/// widget al final. Alto mínimo 56 dp.
/// Ref: ux-ui.md §2.6 (ListTile).
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Reemplaza a [icon] (p. ej. un Avatar).
  final Widget? leading;

  /// Reemplaza al chevron.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Texto e icono en rojo (p. ej. "Cerrar sesión").
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? CustomColors.error : CustomColors.primary;
    final lead =
        leading ??
        (icon == null
            ? null
            : Icon(
                icon,
                size: 22,
                color: destructive ? CustomColors.error : CustomColors.tealMuted,
              ));
    final trail =
        trailing ??
        (showChevron && onTap != null
            ? const Icon(
                CustomIcons.chevronRight,
                size: 22,
                color: CustomColors.textMuted,
              )
            : null);

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (lead != null) ...[lead, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: CustomTypography.verdana(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: CustomTypography.bodySmall.copyWith(
                          color: CustomColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trail != null) ...[const SizedBox(width: 8), trail],
            ],
          ),
        ),
      ),
    );
  }
}
