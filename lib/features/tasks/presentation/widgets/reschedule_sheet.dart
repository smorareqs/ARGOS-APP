import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/tasks/data/repositories/tasks_repository.dart';
import 'package:argos_app/features/tasks/models/task_detail.dart';
import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// C2 · Reasignar / reprogramar: otra persona, otro día u otra ventana, con
/// el motivo (queda en la línea de tiempo). Necesita conexión.
Future<bool> showRescheduleSheet(BuildContext context, TaskSummary task) async =>
    await showArgosSheet<bool>(context, builder: (_) => _RescheduleSheet(task: task)) ?? false;

class _RescheduleSheet extends ConsumerStatefulWidget {
  const _RescheduleSheet({required this.task});

  final TaskSummary task;

  @override
  ConsumerState<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends ConsumerState<_RescheduleSheet> {
  late final Future<List<TaskAssignee>> _people = ref.read(tasksRepositoryProvider).assignables();
  late String? _assignee = widget.task.assigneeId;
  late DateTime _date = widget.task.scheduledDate;
  late String _start = widget.task.windowStart ?? '09:00';
  late String _end = widget.task.windowEnd ?? '11:00';
  final _reason = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _changed =>
      _assignee != widget.task.assigneeId ||
      !DateUtils.isSameDay(_date, widget.task.scheduledDate) ||
      _start != widget.task.windowStart ||
      _end != widget.task.windowEnd;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 120)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(current.substring(0, 2)),
        minute: int.parse(current.substring(3, 5)),
      ),
    );
    if (picked == null) return;
    final v = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => start ? _start = v : _end = v);
  }

  Future<void> _save() async {
    if (_start.compareTo(_end) >= 0) {
      showToast(context, 'La hora de fin debe ser después del inicio.');
      return;
    }
    setState(() => _saving = true);
    try {
      final t = widget.task;
      await ref.read(tasksRepositoryProvider).reschedule(
        t.id,
        changeAssignee: _assignee != t.assigneeId,
        assigneeId: _assignee,
        date: DateUtils.isSameDay(_date, t.scheduledDate) ? null : _date,
        start: _start == t.windowStart ? null : _start,
        end: _end == t.windowEnd ? null : _end,
        reason: _reason.text.trim(),
      );
      if (!mounted) return;
      showToast(context, 'Cambio guardado.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Reasignar o reprogramar',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('QUIÉN', style: CustomTypography.label),
            const SizedBox(height: 8),
            FutureBuilder<List<TaskAssignee>>(
              future: _people,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Text(errorMessage(snap.error!), style: CustomTypography.bodySmall);
                }
                final people = snap.data;
                if (people == null) return const Skeleton(width: double.infinity, height: 48);
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in people)
                      ChoiceChip(
                        avatar: Avatar(name: p.name, size: 22),
                        label: Text(p.name),
                        selected: _assignee == p.id,
                        onSelected: p.covers(widget.task.property.id)
                            ? (_) => setState(() => _assignee = p.id)
                            : null,
                        tooltip: p.covers(widget.task.property.id)
                            ? null
                            : 'No tiene asignada esta propiedad',
                      ),
                    ChoiceChip(
                      label: const Text('Sin asignar'),
                      selected: _assignee == null,
                      onSelected: (_) => setState(() => _assignee = null),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text('CUÁNDO', style: CustomTypography.label),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppListTile(
                    icon: CustomIcons.today,
                    title: DateLabels.longDate(_date),
                    onTap: _pickDate,
                  ),
                  AppListTile(
                    icon: CustomIcons.time,
                    title: '$_start – $_end',
                    subtitle: 'Toca para cambiar el inicio',
                    onTap: () => _pickTime(true),
                    trailing: TextButton(onPressed: () => _pickTime(false), child: const Text('Fin')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('MOTIVO', style: CustomTypography.label),
            const SizedBox(height: 8),
            AppTextField(
              controller: _reason,
              hintText: 'Ej.: Ana está incapacitada',
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Confirmar',
              isLoading: _saving,
              onPressed: !_changed || _reason.text.trim().isEmpty || _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
