import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_motion.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Una opción de [FilterChips].
class FilterOption<T> {
  const FilterOption({required this.value, required this.label, this.count});

  final T value;
  final String label;

  /// Conteo opcional ("Pendientes · 3").
  final int? count;
}

/// Chips de filtro ARGOS — fila horizontal con scroll; selección única o
/// múltiple. El activo va en teal con check.
/// Ref: ux-ui.md §2.6 (FilterChips) y §3.2.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.multiple = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<FilterOption<T>> options;
  final Set<T> selected;

  /// Recibe el nuevo conjunto seleccionado.
  final ValueChanged<Set<T>> onChanged;

  /// En selección única, tocar el activo lo deselecciona.
  final bool multiple;
  final EdgeInsetsGeometry padding;

  void _toggle(T value) {
    final next = Set<T>.of(selected);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      if (!multiple) next.clear();
      next.add(value);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final option = options[i];
          return Center(
            child: _FilterChip(
              label: option.count == null
                  ? option.label
                  : '${option.label} · ${option.count}',
              active: selected.contains(option.value),
              onTap: () => _toggle(option.value),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = CustomMotion.resolve(context, CustomMotion.fast);
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
          child: AnimatedContainer(
            duration: duration,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: active ? CustomColors.primary : CustomColors.surface,
              borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
              border: Border.all(
                color: active ? CustomColors.primary : CustomColors.borderField,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (active) ...[
                  const Icon(
                    CustomIcons.done,
                    size: 16,
                    color: CustomColors.onPrimary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: CustomTypography.verdana(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: active
                        ? CustomColors.onPrimary
                        : CustomColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
