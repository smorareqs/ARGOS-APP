import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Tono de un aviso: decide el color del icono.
enum NotificationTone { info, success, warning, danger }

/// Fila de la bandeja de avisos (B16): icono por tipo, título, cuerpo, hora
/// relativa y punto si no se ha leído.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.time,
    this.body,
    this.tone = NotificationTone.info,
    this.unread = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? body;

  /// Ya formateada ("hace 5 min").
  final String time;
  final NotificationTone tone;
  final bool unread;
  final VoidCallback? onTap;

  (Color, Color) get _colors => switch (tone) {
    NotificationTone.info => (CustomColors.infoSoft, CustomColors.primary),
    NotificationTone.success => (CustomColors.successSoft, CustomColors.success),
    NotificationTone.warning => (CustomColors.warningSoft, CustomColors.warning),
    NotificationTone.danger => (CustomColors.errorSoft, CustomColors.error),
  };

  @override
  Widget build(BuildContext context) {
    final (soft, strong) = _colors;
    return Semantics(
      button: onTap != null,
      label: unread ? 'Sin leer' : null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: unread ? CustomColors.surface : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: CustomDimensions.spacingLg,
            vertical: 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: strong),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: CustomTypography.verdana(
                              fontSize: 13.5,
                              fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                              color: CustomColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: CustomTypography.verdana(
                            fontSize: 11,
                            color: CustomColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (body != null && body!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        body!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: CustomTypography.verdana(
                          fontSize: 12.5,
                          color: CustomColors.textBody,
                        ).copyWith(height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: AnimatedOpacity(
                  opacity: unread ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: CustomColors.secondary,
                      shape: BoxShape.circle,
                    ),
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
