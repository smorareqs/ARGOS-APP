import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Estado de envío de un mensaje propio.
enum ChatSendState { sent, sending, failed }

/// Burbuja de chat (B23): propias en teal a la derecha, ajenas en superficie
/// a la izquierda con el nombre de quien escribe en los grupos. Los mensajes
/// del sistema van centrados.
/// Ref: ux-ui.md B23.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.mine,
    required this.time,
    this.body,
    this.sender,
    this.image,
    this.state = ChatSendState.sent,
    this.onRetry,
    this.onOpenImage,
    this.system = false,
    this.grouped = false,
  });

  final bool mine;
  final String time;
  final String? body;

  /// Nombre de quien escribe (solo ajenas, en grupos).
  final String? sender;

  /// Foto adjunta (ya resuelta por la app: red o memoria).
  final ImageProvider? image;
  final ChatSendState state;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenImage;
  final bool system;

  /// Sigue a otro mensaje de la misma persona: menos espacio arriba.
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    if (system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: CustomColors.tealWashed,
            borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
          ),
          child: Text(
            body ?? '',
            textAlign: TextAlign.center,
            style: CustomTypography.bodySmall.copyWith(color: CustomColors.tealMuted),
          ),
        ),
      );
    }
    final bg = mine ? CustomColors.primary : CustomColors.surface;
    final fg = mine ? Colors.white : CustomColors.textPrimary;
    const r = Radius.circular(18);
    const tail = Radius.circular(6);
    final radius = BorderRadius.only(
      topLeft: r,
      topRight: r,
      bottomLeft: mine ? r : tail,
      bottomRight: mine ? tail : r,
    );
    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: CustomTypography.verdana(fontSize: 10.5, color: mine ? Colors.white.withValues(alpha: 0.65) : CustomColors.textMuted),
        ),
        if (mine) ...[
          const SizedBox(width: 4),
          Icon(
            switch (state) {
              ChatSendState.sent => CustomIcons.check,
              ChatSendState.sending => CustomIcons.time,
              ChatSendState.failed => CustomIcons.error,
            },
            size: 13,
            color: state == ChatSendState.failed ? CustomColors.errorOnDark : Colors.white.withValues(alpha: 0.7),
          ),
        ],
      ],
    );

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: mine ? null : Border.all(color: CustomColors.border),
      ),
      padding: EdgeInsets.fromLTRB(image == null ? 14 : 4, image == null ? 9 : 4, image == null ? 12 : 4, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sender != null && !mine) ...[
            Padding(
              padding: EdgeInsets.only(left: image == null ? 0 : 10, top: image == null ? 0 : 6),
              child: Text(
                sender!,
                style: CustomTypography.verdana(fontSize: 11.5, fontWeight: FontWeight.w700, color: CustomColors.secondary),
              ),
            ),
            const SizedBox(height: 2),
          ],
          if (image != null)
            GestureDetector(
              onTap: onOpenImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image(
                  image: image!,
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 220,
                    height: 120,
                    color: CustomColors.track,
                    alignment: Alignment.center,
                    child: const Icon(CustomIcons.photo, color: CustomColors.textMuted),
                  ),
                ),
              ),
            ),
          if (body != null && body!.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(image == null ? 0 : 10, image == null ? 0 : 8, image == null ? 0 : 10, 2),
              child: Text(body!, style: CustomTypography.verdana(fontSize: 14.5, color: fg, height: 1.4)),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(padding: EdgeInsets.only(right: image == null ? 0 : 8, top: 2), child: meta),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(top: grouped ? 2 : 8, left: mine ? 48 : 0, right: mine ? 0 : 48),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          bubble,
          if (state == ChatSendState.failed)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                foregroundColor: CustomColors.error,
              ),
              child: Text('No se envió · Reintentar', style: CustomTypography.verdana(fontSize: 12, color: CustomColors.error)),
            ),
        ],
      ),
    );
  }
}

/// Separador de día entre mensajes ("Hoy", "Ayer", "lunes 18 de nov.").
class ChatDayDivider extends StatelessWidget {
  const ChatDayDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: CustomColors.neutralSoft,
            borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
          ),
          child: Text(label, style: CustomTypography.verdana(fontSize: 11.5, color: CustomColors.textSecondary)),
        ),
      ),
    );
  }
}
