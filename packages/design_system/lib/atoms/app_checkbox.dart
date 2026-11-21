import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Casilla grande ARGOS — 32 dp visibles dentro de un área táctil de 48 dp.
/// Marcada: fondo teal con check blanco; sin marcar: borde de campo.
/// Ref: ux-ui.md §2.6 (Checkbox grande, fase 2).
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;

  /// Si es null la casilla queda deshabilitada.
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final duration = CustomMotion.resolve(context, CustomMotion.fast);
    final fill = value
        ? (enabled ? CustomColors.primary : CustomColors.disabled)
        : CustomColors.surface;
    final border = value
        ? fill
        : (enabled ? CustomColors.tealMuted : CustomColors.borderField);

    return Semantics(
      checked: value,
      enabled: enabled,
      label: semanticLabel,
      child: InkResponse(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              }
            : null,
        radius: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              curve: CustomMotion.enter,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: border, width: 2),
              ),
              child: AnimatedSwitcher(
                duration: duration,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: value
                    ? const Icon(
                        CustomIcons.done,
                        key: ValueKey('on'),
                        size: 22,
                        color: CustomColors.onPrimary,
                      )
                    : const SizedBox.shrink(key: ValueKey('off')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
