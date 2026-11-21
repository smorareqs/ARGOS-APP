import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Barra fija de "sin conexión" bajo la cabecera.
/// Ej.: "Sin conexión · mostrando datos guardados hace 12 min".
/// Ref: ux-ui.md §3.1 (Sin conexión).
class OfflineBar extends StatelessWidget {
  const OfflineBar({super.key, this.detail});

  /// Texto tras el punto medio (p. ej. "mostrando datos guardados hace 12 min").
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final text = detail == null ? 'Sin conexión' : 'Sin conexión · $detail';
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: CustomColors.offline,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(CustomIcons.offline, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: CustomTypography.verdana(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
