import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Botón grande de desbloqueo biométrico. El diálogo real lo muestra el
/// sistema operativo; este componente lo invoca y lo vuelve a ofrecer.
/// Ref: ux-ui.md §2.6 (BiometricPrompt) · A5 y A6.
class BiometricPrompt extends StatelessWidget {
  const BiometricPrompt({
    super.key,
    required this.onPressed,
    this.label = 'Usar huella o rostro',
    this.onDark = false,
    this.isBusy = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool onDark;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : CustomColors.primary;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: isBusy ? null : onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : CustomColors.tealWashed,
                  border: Border.all(
                    color: CustomColors.secondary.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: isBusy
                    ? const Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CustomColors.secondary,
                        ),
                      )
                    : Icon(CustomIcons.fingerprint, size: 48, color: foreground),
              ),
              const SizedBox(height: 10),
              ExcludeSemantics(
                child: Text(
                  label,
                  style: CustomTypography.verdana(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: onDark
                        ? Colors.white.withValues(alpha: 0.85)
                        : CustomColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
