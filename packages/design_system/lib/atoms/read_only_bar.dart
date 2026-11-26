import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Banda de "solo lectura" o "pago vencido" sobre el contenido. La empresa
/// sigue viendo todo, pero las escrituras responden 402 (fase06 §3).
class ReadOnlyBar extends StatelessWidget {
  const ReadOnlyBar({super.key, required this.message, this.soft = false});

  final String message;

  /// true: aviso (pago vencido, aún se puede trabajar); false: bloqueo.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final fg = soft ? CustomColors.warning : Colors.white;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: soft ? CustomColors.warningSoft : CustomColors.warning,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(soft ? CustomIcons.info : CustomIcons.readOnly, size: 16, color: fg),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: CustomTypography.verdana(fontSize: 12, color: fg, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}
