import 'package:design_system/tokens/custom_colors.dart';
import 'package:flutter/material.dart';

/// Botón de icono ARGOS — área táctil de 48 dp y etiqueta de accesibilidad
/// obligatoria (se muestra también como tooltip).
/// Ref: ux-ui.md §2.6 (IconButton) y §3.8.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.color = CustomColors.primary,
    this.size = 24,
  });

  final IconData icon;

  /// Lo que anuncia el lector de pantalla (p. ej. "Volver").
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: semanticLabel,
      icon: Icon(icon, size: size),
      color: color,
      disabledColor: CustomColors.disabled,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}
