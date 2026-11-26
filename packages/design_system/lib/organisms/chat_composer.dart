import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// ChatComposer (N, 6): campo de texto que crece hasta 5 líneas, cámara
/// opcional y botón de enviar que se activa con texto o foto lista.
/// Ref: ux-ui.md B23.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.onCamera,
    this.attachment,
    this.canSend = false,
    this.enabled = true,
    this.hintText = 'Escribe un mensaje',
    this.disabledText,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  /// null: sin cámara (el huésped solo escribe texto).
  final VoidCallback? onCamera;

  /// Vista previa de la foto por mandar (con su estado de subida).
  final Widget? attachment;
  final bool canSend;
  final bool enabled;
  final String hintText;

  /// Texto en lugar del campo cuando no se puede escribir (archivada).
  final String? disabledText;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: CustomColors.surface,
        border: Border(top: BorderSide(color: CustomColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottom),
      child: !enabled
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                disabledText ?? 'No puedes escribir aquí.',
                textAlign: TextAlign.center,
                style: CustomTypography.bodySmall,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (attachment != null) Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), child: attachment),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (onCamera != null)
                      IconButton(
                        onPressed: onCamera,
                        tooltip: 'Tomar foto',
                        icon: const Icon(CustomIcons.camera, color: CustomColors.tealMuted),
                      ),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: CustomColors.background,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: CustomColors.borderField),
                        ),
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          style: CustomTypography.verdana(fontSize: 15, color: CustomColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: CustomTypography.verdana(fontSize: 15, color: CustomColors.textMuted),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Semantics(
                      button: true,
                      label: 'Enviar',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: canSend ? CustomColors.primary : CustomColors.track,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: canSend ? onSend : null,
                          icon: Icon(CustomIcons.send, size: 19, color: canSend ? Colors.white : CustomColors.disabled),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
