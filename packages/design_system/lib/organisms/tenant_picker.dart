import 'package:design_system/atoms/avatar.dart';
import 'package:design_system/molecules/app_card.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Una empresa elegible en el [TenantPicker].
class TenantOption {
  const TenantOption({
    required this.id,
    required this.name,
    required this.roleName,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String roleName;
  final String? logoUrl;
}

/// Lista de empresas con logo, nombre y rol. La marcada como [highlightedId]
/// (la última usada o la activa) va primero y con distintivo.
/// Ref: ux-ui.md §2.6 (TenantPicker) · A4.
class TenantPicker extends StatelessWidget {
  const TenantPicker({
    super.key,
    required this.options,
    required this.onSelect,
    this.highlightedId,
    this.highlightLabel = 'Última usada',
    this.busyId,
  });

  final List<TenantOption> options;
  final ValueChanged<TenantOption> onSelect;
  final String? highlightedId;
  final String highlightLabel;

  /// Empresa cuya selección está en curso (muestra un indicador y bloquea).
  final String? busyId;

  @override
  Widget build(BuildContext context) {
    final sorted = [...options]
      ..sort((a, b) {
        if (a.id == highlightedId) return -1;
        if (b.id == highlightedId) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in sorted) ...[
          _tile(option),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _tile(TenantOption option) {
    final highlighted = option.id == highlightedId;
    final busy = option.id == busyId;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: busyId == null ? () => onSelect(option) : null,
      child: Row(
        children: [
          Avatar(
            name: option.name,
            imageUrl: option.logoUrl,
            size: 44,
            variant: AvatarVariant.company,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option.name, style: CustomTypography.cardTitle),
                const SizedBox(height: 2),
                Text(
                  option.roleName,
                  style: CustomTypography.bodySmall.copyWith(
                    color: CustomColors.textSecondary,
                  ),
                ),
                if (highlighted) ...[
                  const SizedBox(height: 6),
                  Text(
                    highlightLabel.toUpperCase(),
                    style: CustomTypography.label.copyWith(
                      color: CustomColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (busy)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CustomColors.secondary,
              ),
            )
          else
            const Icon(
              CustomIcons.chevronRight,
              color: CustomColors.textMuted,
            ),
        ],
      ),
    );
  }
}
