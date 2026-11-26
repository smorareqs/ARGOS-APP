import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/features/hr/data/hr_repository.dart';
import 'package:argos_app/features/hr/models/hr.dart';
import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:argos_app/features/tasks/presentation/providers/agenda_providers.dart';
import 'package:argos_app/features/tasks/presentation/widgets/agenda_task_card.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// C1 · Equipo hoy (supervisor y admin): resumen de las tareas del día por
/// estado y la lista por colaborador. "Por validar" muestra primero las
/// terminadas que esperan revisión (C3).
class TeamPage extends ConsumerStatefulWidget {
  const TeamPage({super.key, this.today});

  final DateTime? today;

  @override
  ConsumerState<TeamPage> createState() => _TeamPageState();
}

enum _TeamFilter { all, review, active, late, unassigned }

class _TeamPageState extends ConsumerState<TeamPage> {
  late DateTime _date = DateUtils.dateOnly(widget.today ?? DateTime.now());
  var _filter = _TeamFilter.all;

  Future<void> _refresh() =>
      ref.refresh(dayAgendaProvider(_date, mine: false).future).then((_) {}, onError: (_) {});

  bool _matches(TaskSummary t) => switch (_filter) {
    _TeamFilter.all => true,
    _TeamFilter.review => t.status == TaskStatus.done,
    _TeamFilter.active => t.status == TaskStatus.inProgress,
    _TeamFilter.late => t.showsLate,
    _TeamFilter.unassigned => t.assigneeId == null,
  };

  @override
  Widget build(BuildContext context) {
    final agenda = ref.watch(dayAgendaProvider(_date, mine: false));
    final tasks = agenda.valueOrNull?.tasks ?? const <TaskSummary>[];
    final active = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final review = tasks.where((t) => t.status == TaskStatus.done).length;
    final late = tasks.where((t) => t.showsLate).length;
    final unassigned = tasks.where((t) => t.assigneeId == null).length;

    final groups = <String, List<TaskSummary>>{};
    final idOf = <String, String>{};
    for (final t in tasks.where(_matches)) {
      final name = t.assigneeName ?? 'Sin asignar';
      groups.putIfAbsent(name, () => []).add(t);
      if (t.assigneeId != null) idOf[name] = t.assigneeId!;
    }
    // Quién marcó ese día (solo se muestra si hay marcajes que leer).
    final punches = ref.watch(teamAttendanceProvider(_dayKey(_date))).valueOrNull ?? const <AttendanceRecord>[];
    final today = DateUtils.dateOnly(widget.today ?? DateTime.now());

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateUtils.isSameDay(_date, today) ? 'Equipo hoy' : 'Equipo',
                        style: CustomTypography.pageTitle,
                      ),
                      Text(DateLabels.longDate(_date), style: CustomTypography.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Día anterior',
                  icon: const Icon(Icons.chevron_left_rounded, color: CustomColors.primary),
                  onPressed: () => setState(() => _date = _date.subtract(const Duration(days: 1))),
                ),
                IconButton(
                  tooltip: 'Día siguiente',
                  icon: const Icon(CustomIcons.chevronRight, color: CustomColors.primary),
                  onPressed: () => setState(() => _date = _date.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),
          if (agenda.valueOrNull?.fromCache ?? false)
            OfflineBar(detail: 'mostrando datos guardados ${DateLabels.relative(agenda.value!.cachedAt!)}'),
          Expanded(
            child: RefreshIndicator(
              color: CustomColors.primary,
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (agenda.isLoading && !agenda.hasValue)
                    for (var i = 0; i < 3; i++) ...[
                      const Skeleton(width: double.infinity, height: 120, radius: CustomDimensions.radiusCard),
                      const SizedBox(height: 12),
                    ]
                  else if (agenda.hasError && !agenda.hasValue)
                    ErrorState(
                      message: agenda.error is DioException
                          ? 'Sin conexión y sin datos guardados de este día.'
                          : 'No pudimos cargar las tareas del equipo.',
                      onRetry: _refresh,
                    )
                  else if (tasks.isEmpty)
                    const EmptyState(
                      icon: CustomIcons.team,
                      title: 'Sin tareas este día',
                      message: 'Las limpiezas de salida se crean solas con cada reserva confirmada.',
                    )
                  else ...[
                    _Summary(
                      total: tasks.length,
                      active: active,
                      review: review,
                      late: late,
                    ),
                    const SizedBox(height: 14),
                    FilterChips<_TeamFilter>(
                      padding: EdgeInsets.zero,
                      options: [
                        FilterOption(value: _TeamFilter.all, label: 'Todas', count: tasks.length),
                        if (review > 0) FilterOption(value: _TeamFilter.review, label: 'Por validar', count: review),
                        if (active > 0) FilterOption(value: _TeamFilter.active, label: 'En progreso', count: active),
                        if (late > 0) FilterOption(value: _TeamFilter.late, label: 'Retrasadas', count: late),
                        if (unassigned > 0)
                          FilterOption(value: _TeamFilter.unassigned, label: 'Sin asignar', count: unassigned),
                      ],
                      selected: {_filter},
                      onChanged: (s) => setState(() => _filter = s.isEmpty ? _TeamFilter.all : s.first),
                    ),
                    const SizedBox(height: 18),
                    for (final e in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
                        child: Row(
                          children: [
                            Avatar(name: e.key, size: 32),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.key, style: CustomTypography.cardTitle),
                                  if (punches.isNotEmpty && idOf[e.key] != null)
                                    _Punch(records: punches.where((r) => r.userId == idOf[e.key]).toList()),
                                ],
                              ),
                            ),
                            Text(
                              '${e.value.where((t) => t.status.isFinished).length}/${e.value.length}',
                              style: CustomTypography.data.copyWith(color: CustomColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      for (final t in e.value) ...[
                        AgendaTaskCard(
                          task: t,
                          unsynced: agenda.valueOrNull?.unsynced.contains(t.id) ?? false,
                          onTap: () => context.push('/tasks/${t.id}', extra: t),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 8),
                    ],
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

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Estado de marcaje de la persona ese día.
class _Punch extends StatelessWidget {
  const _Punch({required this.records});

  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final open = records.where((r) => r.open).firstOrNull;
    final last = records.lastOrNull;
    final (color, text) = open != null
        ? (CustomColors.success, 'Entró ${hm(open.clockIn)}')
        : last != null
        ? (CustomColors.textSecondary, 'Salió ${hm(last.clockOut!)}')
        : (CustomColors.textMuted, 'Sin marcar entrada');
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: CustomTypography.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.total, required this.active, required this.review, required this.late});

  final int total;
  final int active;
  final int review;
  final int late;

  @override
  Widget build(BuildContext context) {
    Widget tile(String value, String label, {Color? color}) => Expanded(
      child: Column(
        children: [
          Text(value, style: CustomTypography.pageTitle.copyWith(color: color ?? CustomColors.primary)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: CustomTypography.bodySmall),
        ],
      ),
    );
    return AppCard(
      child: Row(
        children: [
          tile('$total', 'Tareas'),
          tile('$active', 'En progreso', color: CustomColors.secondary),
          tile('$review', 'Por validar', color: CustomColors.success),
          tile('$late', 'Retrasadas', color: late > 0 ? CustomColors.warning : null),
        ],
      ),
    );
  }
}
