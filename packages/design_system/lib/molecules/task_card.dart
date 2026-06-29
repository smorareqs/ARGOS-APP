import 'package:design_system/atoms/progress_bar.dart';
import 'package:design_system/atoms/status_badge.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_shadows.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Una fila de metadato dentro de una [TaskCard] (icono + texto).
class TaskMeta {
  const TaskMeta({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Tarjeta de tarea del Itinerario — propiedad, dirección, estado y metadatos.
/// Soporta las 4 variantes del diseño mediante banderas/opcionales:
///   · En progreso  → `accented: true` + `checklist`
///   · Pendiente    → estado pending
///   · Incidencia   → `incident`
///   · Finalizada   → `completed: true`
/// Ref: ARGOS App · lista de tareas del Itinerario.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.title,
    required this.address,
    required this.statusLabel,
    required this.statusVariant,
    this.meta = const [],
    this.checklistDone,
    this.checklistTotal,
    this.incident,
    this.completedNote,
    this.accented = false,
    this.completed = false,
    this.onTap,
  });

  final String title;
  final String address;
  final String statusLabel;
  final StatusBadgeVariant statusVariant;

  /// Filas de metadato (hora, tipo de servicio…).
  final List<TaskMeta> meta;

  /// Progreso de checklist (ambos no nulos → muestra la barra).
  final int? checklistDone;
  final int? checklistTotal;

  /// Banner de avería reportada.
  final String? incident;

  /// Nota de cierre (p. ej. "08:00 – 09:20 · 12 fotos de evidencia").
  final String? completedNote;

  /// Borde dorado izquierdo — tarjeta destacada (en progreso).
  final bool accented;

  /// Estilo finalizado — superficie suave, título tachado, atenuado.
  final bool completed;

  final VoidCallback? onTap;

  bool get _showChecklist =>
      checklistDone != null && checklistTotal != null && checklistTotal! > 0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CustomDimensions.radiusCard);

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: completed ? CustomColors.surfaceSoft : CustomColors.surface,
        borderRadius: radius,
        // Borde uniforme dorado tenue para la variante acentuada (Flutter no
        // admite borderRadius con bordes de color no uniforme).
        border: accented
            ? Border.all(color: CustomColors.secondary.withValues(alpha: 0.35))
            : null,
        boxShadow: CustomShadows.card,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Franja izquierda dorada (border-left:4px del diseño).
            if (accented)
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 4,
                  child: ColoredBox(color: CustomColors.secondary),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                accented ? CustomDimensions.spacingMd + 4 : CustomDimensions.spacingMd,
                CustomDimensions.spacingMd,
                CustomDimensions.spacingMd,
                CustomDimensions.spacingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    _metaRow(),
                  ],
                  if (_showChecklist) ...[
                    const SizedBox(height: 14),
                    _checklist(),
                  ],
                  if (incident != null) ...[
                    const SizedBox(height: 12),
                    _incidentBanner(),
                  ],
                  if (completedNote != null) ...[
                    const SizedBox(height: 11),
                    _completedRow(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CustomTypography.garamond(fontSize: 18).copyWith(
                  color: completed ? const Color(0xFF5A6B6B) : CustomColors.primary,
                  decoration: completed ? TextDecoration.lineThrough : null,
                  decorationColor: CustomColors.primary.withValues(alpha: 0.25),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                style: CustomTypography.verdana(
                  fontSize: 12,
                  color: completed
                      ? CustomColors.textMuted
                      : CustomColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: CustomDimensions.spacingSm),
        StatusBadge(label: statusLabel, variant: statusVariant),
      ],
    );
  }

  Widget _metaRow() {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        for (final m in meta)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(m.icon, size: 14, color: CustomColors.textMuted),
              const SizedBox(width: 6),
              Text(
                m.label,
                style: CustomTypography.verdana(
                  fontSize: 12,
                  color: completed
                      ? CustomColors.textMuted
                      : CustomColors.textBody,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _checklist() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Checklist',
              style: CustomTypography.verdana(
                fontSize: 11,
                color: CustomColors.textSecondary,
              ),
            ),
            Text(
              '$checklistDone / $checklistTotal',
              style: CustomTypography.verdana(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: CustomColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ProgressBar(value: checklistDone! / checklistTotal!),
      ],
    );
  }

  Widget _incidentBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: CustomColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          const Icon(CustomIcons.incident, size: 15, color: CustomColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              incident!,
              style: CustomTypography.verdana(
                fontSize: 11.5,
                color: CustomColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedRow() {
    return Row(
      children: [
        const Icon(CustomIcons.time, size: 14, color: CustomColors.disabled),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            completedNote!,
            style: CustomTypography.verdana(
              fontSize: 12,
              color: CustomColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
