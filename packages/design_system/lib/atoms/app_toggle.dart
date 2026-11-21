import 'package:design_system/tokens/custom_colors.dart';
import 'package:flutter/material.dart';

/// Interruptor ARGOS — pista dorada cuando está activo.
/// Ref: ux-ui.md §2.6 (Toggle).
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: CustomColors.secondary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: CustomColors.borderField,
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
