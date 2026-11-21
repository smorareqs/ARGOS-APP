import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Tono del punto de un [TimelineItem].
enum TimelineTone { neutral, info, success, warning, error }

/// Evento de bitácora ARGOS — punto de color con icono, línea que lo une al
/// siguiente, título, hora y detalle opcional.
/// Ref: ux-ui.md §2.6 (TimelineItem): historial de tarea, ticket o reserva.
class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.title,
    required this.time,
    this.icon,
    this.detail,
    this.tone = TimelineTone.neutral,
    this.isFirst = false,
    this.isLast = false,
  });

  final String title;

  /// Ya formateada ("09:42" o "ayer").
  final String time;
  final IconData? icon;
  final String? detail;
  final TimelineTone tone;
  final bool isFirst;
  final bool isLast;

  (Color, Color) get _colors => switch (tone) {
    TimelineTone.neutral => (CustomColors.neutralSoft, CustomColors.textBody),
    TimelineTone.info => (CustomColors.infoSoft, CustomColors.primary),
    TimelineTone.success => (CustomColors.successSoft, CustomColors.success),
    TimelineTone.warning => (CustomColors.warningSoft, CustomColors.warning),
    TimelineTone.error => (CustomColors.errorSoft, CustomColors.error),
  };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 6,
                  color: isFirst ? Colors.transparent : CustomColors.border,
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: icon == null
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: foreground,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : Icon(icon, size: 16, color: foreground),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : CustomColors.border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: CustomTypography.verdana(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: CustomColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: CustomTypography.bodySmall.copyWith(
                          color: CustomColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      style: CustomTypography.bodySmall.copyWith(
                        color: CustomColors.textBody,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
