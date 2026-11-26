import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/features/tickets/models/ticket.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Tarjeta de incidencia (B13): urgencia en el borde, folio, título, lugar,
/// activo, estado y cuánto lleva abierta.
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket, this.onTap, this.now});

  final Ticket ticket;
  final VoidCallback? onTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final reference = now ?? DateTime.now();
    return Semantics(
      button: onTap != null,
      label: 'Incidencia ${t.number}, urgencia ${t.urgency.label}',
      child: Material(
        color: CustomColors.surface,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
              border: Border.all(color: CustomColors.border),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: t.urgency.color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('#${t.number}', style: CustomTypography.mono.copyWith(fontSize: 12)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: t.urgency.soft,
                                  borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
                                ),
                                child: Text(
                                  t.urgency.label,
                                  style: CustomTypography.verdana(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: t.urgency.color,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              StatusBadge(label: t.status.label, variant: t.status.badge),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(t.title, style: CustomTypography.cardTitle),
                          const SizedBox(height: 4),
                          Text(
                            [if (t.place.isNotEmpty) t.place, if (t.assetName != null) t.assetName!].join(' · '),
                            style: CustomTypography.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(CustomIcons.time, size: 14, color: CustomColors.textMuted),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  t.status.active
                                      ? 'Abierta ${_age(t.createdAt, reference)}'
                                      : 'Reportada ${DateLabels.relative(t.createdAt, now: reference)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CustomTypography.bodySmall,
                                ),
                              ),
                              if (t.photosCount > 0) ...[
                                const SizedBox(width: 12),
                                const Icon(CustomIcons.photo, size: 14, color: CustomColors.textMuted),
                                const SizedBox(width: 4),
                                Text('${t.photosCount}', style: CustomTypography.bodySmall),
                              ],
                              if (t.assigneeName != null) ...[
                                const SizedBox(width: 12),
                                const Spacer(),
                                Avatar(name: t.assigneeName!, size: 22),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _age(DateTime from, DateTime now) {
    final d = now.difference(from);
    if (d.inMinutes < 60) return 'hace ${d.inMinutes.clamp(1, 59)} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    return 'hace ${d.inDays} ${d.inDays == 1 ? 'día' : 'días'}';
  }
}

/// Orden de B13: más urgentes primero y, entre iguales, las más viejas.
List<Ticket> sortByUrgency(List<Ticket> list) => [...list]
  ..sort((a, b) {
    if (a.status.active != b.status.active) return a.status.active ? -1 : 1;
    final u = b.urgency.index.compareTo(a.urgency.index);
    return u != 0 ? u : a.createdAt.compareTo(b.createdAt);
  });
