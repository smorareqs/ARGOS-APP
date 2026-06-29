import 'package:design_system/atoms/summary_chip.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Una métrica de resumen para el [ItineraryHeader].
class HeaderSummary {
  const HeaderSummary({
    required this.value,
    required this.label,
    this.suffix,
    this.highlight = false,
  });

  final String value;
  final String label;
  final String? suffix;

  /// Pinta el número en dorado (acento).
  final bool highlight;
}

/// Encabezado teal del Itinerario — fecha, saludo, avatar, notificaciones
/// y métricas de resumen. Esquinas inferiores redondeadas.
/// Ref: ARGOS App · header del Itinerario.
class ItineraryHeader extends StatelessWidget {
  const ItineraryHeader({
    super.key,
    required this.dateLabel,
    required this.greeting,
    required this.initials,
    required this.summaries,
    this.hasNotification = true,
    this.onTapNotifications,
    this.onTapAvatar,
  });

  final String dateLabel;
  final String greeting;
  final String initials;
  final List<HeaderSummary> summaries;
  final bool hasNotification;
  final VoidCallback? onTapNotifications;
  final VoidCallback? onTapAvatar;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(22, topInset + 20, 22, 24),
      decoration: const BoxDecoration(
        color: CustomColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: CustomTypography.verdana(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      greeting,
                      style: CustomTypography.garamond(
                        fontSize: 27,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              _notificationBell(),
              const SizedBox(width: 12),
              _avatar(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (var i = 0; i < summaries.length; i++) ...[
                Expanded(
                  child: SummaryChip(
                    value: summaries[i].value,
                    label: summaries[i].label,
                    suffix: summaries[i].suffix,
                    valueColor: summaries[i].highlight
                        ? CustomColors.secondary
                        : Colors.white,
                  ),
                ),
                if (i != summaries.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _notificationBell() {
    return GestureDetector(
      onTap: onTapNotifications,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Icon(
                CustomIcons.notifications,
                size: 20,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            if (hasNotification)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CustomColors.secondary,
                    border: Border.all(color: CustomColors.primary, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    return GestureDetector(
      onTap: onTapAvatar,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: CustomColors.secondary,
        ),
        child: Text(
          initials,
          style: CustomTypography.garamond(fontSize: 17, color: Colors.white),
        ),
      ),
    );
  }
}
