import 'package:design_system/atoms/danger_button.dart';
import 'package:design_system/atoms/secondary_button.dart';
import 'package:design_system/atoms/tertiary_button.dart';
import 'package:design_system/templates/sheet_scaffold.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Hoja de confirmación (preajuste de [SheetScaffold]) — nombra el objeto y
/// el efecto. Si es destructiva, el botón de confirmar es rojo y va a la
/// derecha.
/// Ref: ux-ui.md §3.5.
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancelar',
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    void close(bool value) => Navigator.of(context).pop(value);

    return SheetScaffold(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: CustomTypography.body),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TertiaryButton(
                  label: cancelLabel,
                  onPressed: () => close(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: destructive
                    ? DangerButton(
                        label: confirmLabel,
                        onPressed: () => close(true),
                      )
                    : SecondaryButton(
                        label: confirmLabel,
                        onPressed: () => close(true),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Muestra una [ConfirmSheet] y devuelve `true` solo si el usuario confirma.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) async {
  final result = await showArgosSheet<bool>(
    context,
    builder: (_) => ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result ?? false;
}
