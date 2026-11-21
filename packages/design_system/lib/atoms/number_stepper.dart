import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Stepper numérico ARGOS — botones − / + de 48 dp alrededor del valor.
/// Pensado para cantidades de insumos con guantes o manos mojadas.
/// Ref: ux-ui.md §2.6 (Stepper numérico, fase 2).
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.step = 1,
    this.unit,
    this.semanticLabel = 'Cantidad',
  });

  final int value;

  /// Si es null el stepper queda deshabilitado.
  final ValueChanged<int>? onChanged;
  final int min;
  final int? max;
  final int step;

  /// Unidad opcional bajo el número ("uds", "L").
  final String? unit;
  final String semanticLabel;

  bool get _enabled => onChanged != null;
  bool get _canDecrement => _enabled && value - step >= min;
  bool get _canIncrement => _enabled && (max == null || value + step <= max!);

  void _set(int next) {
    HapticFeedback.selectionClick();
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      value: '$value${unit == null ? '' : ' $unit'}',
      increasedValue: _canIncrement ? '${value + step}' : null,
      decreasedValue: _canDecrement ? '${value - step}' : null,
      onIncrease: _canIncrement ? () => _set(value + step) : null,
      onDecrease: _canDecrement ? () => _set(value - step) : null,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: CustomColors.surface,
          borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
          border: Border.all(color: CustomColors.borderField),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: CustomIcons.remove,
              label: 'Restar',
              onTap: _canDecrement ? () => _set(value - step) : null,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Text(
                        '$value',
                        key: ValueKey(value),
                        textAlign: TextAlign.center,
                        style: CustomTypography.verdana(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _enabled
                              ? CustomColors.primary
                              : CustomColors.disabled,
                        ),
                      ),
                    ),
                    if (unit != null)
                      Text(
                        unit!,
                        style: CustomTypography.verdana(
                          fontSize: 10,
                          color: CustomColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _StepButton(
              icon: CustomIcons.add,
              label: 'Sumar',
              onTap: _canIncrement ? () => _set(value + step) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            size: 22,
            color: onTap == null ? CustomColors.disabled : CustomColors.primary,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}
