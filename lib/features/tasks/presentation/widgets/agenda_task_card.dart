import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Etiqueta y variante del estado de una tarea, iguales en lista y detalle.
(String, StatusBadgeVariant) taskStatusBadge(TaskSummary task) {
  if (task.showsLate) return ('Retrasada', StatusBadgeVariant.incident);
  return switch (task.status) {
    TaskStatus.pending => ('Pendiente', StatusBadgeVariant.pending),
    TaskStatus.inProgress => ('En progreso', StatusBadgeVariant.inProgress),
    TaskStatus.completed => ('Terminada', StatusBadgeVariant.operative),
    TaskStatus.validated => ('Validada', StatusBadgeVariant.operative),
    TaskStatus.cancelled => ('Cancelada', StatusBadgeVariant.pending),
  };
}

IconData taskTypeIcon(TaskType type) => switch (type) {
  TaskType.cleaning => CustomIcons.cleaning,
  TaskType.inspection => CustomIcons.inspection,
  TaskType.maintenance => CustomIcons.maintenance,
  TaskType.checkoutReview => CustomIcons.reservations,
};

String hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// [TaskCard] del design system con los datos de una tarea de la agenda.
class AgendaTaskCard extends StatelessWidget {
  const AgendaTaskCard({super.key, required this.task, this.onTap});

  final TaskSummary task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = taskStatusBadge(task);
    final finished = task.status.isFinished;
    final window = task.windowLabel;
    return Semantics(
      button: onTap != null,
      label: '${task.property.name}, ${task.type.label}, $label'
          '${window == null ? '' : ', $window'}',
      child: ExcludeSemantics(
        child: TaskCard(
          title: task.property.name,
          address: '${task.property.code} · ${task.property.address}',
          statusLabel: label,
          statusVariant: variant,
          meta: [
            if (window != null) TaskMeta(icon: CustomIcons.time, label: window),
            TaskMeta(icon: taskTypeIcon(task.type), label: task.type.label),
          ],
          checklistDone: task.status == TaskStatus.inProgress
              ? task.checklistDone
              : null,
          checklistTotal: task.status == TaskStatus.inProgress
              ? task.checklistTotal
              : null,
          incident: task.showsLate && task.windowStart != null
              ? (task.status == TaskStatus.pending
                    ? 'Debió iniciar a las ${task.windowStart}'
                    : 'Debió terminar a las ${task.windowEnd}')
              : null,
          completedNote: finished && task.finishedAt != null
              ? 'Terminada a las ${hhmm(task.finishedAt!)}'
              : null,
          accented: task.status == TaskStatus.inProgress,
          completed: finished,
          onTap: onTap,
        ),
      ),
    );
  }
}
