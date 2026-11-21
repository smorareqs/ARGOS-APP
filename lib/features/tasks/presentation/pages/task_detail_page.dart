import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:argos_app/features/tasks/presentation/widgets/agenda_task_card.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// B3 · Detalle de tarea (primera versión): cabecera con propiedad, código,
/// estado y ventana; dirección, notas, avance del checklist y línea de
/// tiempo. Acceso, reserva asociada, "Cómo llegar" y la ejecución (B4) se
/// agregan cuando existan sus endpoints.
class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.task});

  final TaskSummary? task;

  @override
  Widget build(BuildContext context) {
    final task = this.task;
    if (task == null) {
      return FormScaffold(
        title: 'Tarea no disponible',
        onBack: () => context.pop(),
        children: const [
          EmptyState(
            icon: CustomIcons.today,
            title: 'Abre la tarea desde tu agenda',
            message: 'Vuelve a Hoy y tócala en la lista.',
          ),
        ],
      );
    }

    final (statusLabel, statusVariant) = taskStatusBadge(task);
    final window = task.windowLabel;
    final dateLabel = DateLabels.longDate(task.scheduledDate);
    final action = switch (task.status) {
      TaskStatus.pending => 'Iniciar ${task.type.label.toLowerCase()}',
      TaskStatus.inProgress => 'Continuar',
      _ => null,
    };

    return DetailScaffold(
      overline: '${task.property.code} · ${task.type.label}',
      title: task.property.name,
      subtitle: window == null ? dateLabel : '$dateLabel · $window',
      status: StatusBadge(label: statusLabel, variant: statusVariant),
      banner: task.showsLate && task.windowStart != null
          ? DetailBanner(
              message: task.status == TaskStatus.pending
                  ? 'Debió iniciar a las ${task.windowStart}'
                  : 'Debió terminar a las ${task.windowEnd}',
            )
          : null,
      onBack: () => context.pop(),
      footer: action == null
          ? null
          : PrimaryButton(
              label: action,
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'La ejecución del checklist llega en la siguiente entrega.',
                    ),
                  ),
                ),
            ),
      children: [
        _InfoCard(
          icon: CustomIcons.location,
          label: 'Dirección',
          child: Text(task.property.address, style: CustomTypography.body),
        ),
        if (task.notes != null && task.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoCard(
            icon: CustomIcons.notes,
            label: 'Notas del administrador',
            child: Text(task.notes!, style: CustomTypography.body),
          ),
        ],
        if (task.checklistTotal != null && task.checklistTotal! > 0) ...[
          const SizedBox(height: 12),
          _InfoCard(
            icon: CustomIcons.activities,
            label: 'Checklist',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${task.checklistDone ?? 0} de ${task.checklistTotal} ítems',
                  style: CustomTypography.cardTitle,
                ),
                const SizedBox(height: 12),
                ProgressBar(
                  value: (task.checklistDone ?? 0) / task.checklistTotal!,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        Text('Línea de tiempo', style: CustomTypography.sectionTitle),
        const SizedBox(height: 16),
        ..._timeline(task),
      ],
    );
  }

  static List<Widget> _timeline(TaskSummary task) {
    final events = <(String, String, IconData?, TimelineTone, String?)>[
      (
        'Programada',
        task.windowStart ?? '',
        CustomIcons.today,
        TimelineTone.neutral,
        task.windowLabel == null ? null : 'Ventana ${task.windowLabel}',
      ),
      if (task.startedAt != null)
        ('Iniciada', hhmm(task.startedAt!), CustomIcons.play, TimelineTone.info, null),
      if (task.showsLate)
        ('Marcada como retrasada', '', CustomIcons.pending, TimelineTone.warning, null),
      if (task.finishedAt != null)
        (
          task.status == TaskStatus.validated ? 'Terminada y validada' : 'Terminada',
          hhmm(task.finishedAt!),
          CustomIcons.done,
          TimelineTone.success,
          null,
        ),
    ];
    return [
      for (var i = 0; i < events.length; i++)
        TimelineItem(
          title: events[i].$1,
          time: events[i].$2,
          icon: events[i].$3,
          tone: events[i].$4,
          detail: events[i].$5,
          isFirst: i == 0,
          isLast: i == events.length - 1,
        ),
    ];
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.label, required this.child});

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CustomColors.tealWashed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: CustomColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: CustomTypography.label),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
