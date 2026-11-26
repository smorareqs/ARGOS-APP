import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/tasks/data/repositories/tasks_repository.dart';
import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:argos_app/features/tasks/presentation/providers/agenda_providers.dart';
import 'package:argos_app/features/tasks/presentation/widgets/agenda_task_card.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Filtros de la agenda.
enum _AgendaFilter { all, inProgress, pending, late, finished }

/// B1 · Hoy — qué hago hoy y empezar con un toque (ux-ui.md B1): cabecera
/// con saludo y resumen, semana en curso, filtros y las tareas del día con
/// la que está en progreso arriba y con acento dorado. Deslizar hacia abajo
/// actualiza; sin conexión muestra la última copia guardada.
/// Ref: ARGOS App · Frame 02 · Itinerario.
class ItineraryPage extends ConsumerStatefulWidget {
  const ItineraryPage({super.key, this.onOpenProfile, this.today});

  /// Al tocar el avatar.
  final VoidCallback? onOpenProfile;

  /// Fecha de referencia (por defecto, hoy). Útil en pruebas.
  final DateTime? today;

  @override
  ConsumerState<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends ConsumerState<ItineraryPage> {
  late final DateTime _today = _dateOnly(widget.today ?? DateTime.now());
  late int _selectedDay = _today.weekday % 7; // la semana empieza en domingo
  var _filter = _AgendaFilter.all;

  DateTime get _sunday =>
      DateTime(_today.year, _today.month, _today.day - _today.weekday % 7);
  DateTime get _selectedDate =>
      DateTime(_sunday.year, _sunday.month, _sunday.day + _selectedDay);
  bool get _isToday => _selectedDate == _today;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _refresh() =>
      ref.refresh(dayAgendaProvider(_selectedDate).future).then((_) {}, onError: (_) {});

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider);
    final user = state is AuthSignedIn ? state.session.user : null;
    final agenda = ref.watch(dayAgendaProvider(_selectedDate));
    final tasks = agenda.valueOrNull?.tasks ?? const <TaskSummary>[];

    final days = [
      for (var i = 0; i < 7; i++)
        _weekDay(_sunday.add(Duration(days: i)), selected: i == _selectedDay),
    ];

    final cachedAt = agenda.valueOrNull?.cachedAt;
    final offline = cachedAt != null || (state is AuthSignedIn && state.offline);

    return Column(
      children: [
        ItineraryHeader(
          dateLabel: DateLabels.longDate(_today),
          greeting: user == null ? 'Hola' : 'Hola, ${user.firstName}',
          initials: user == null ? '' : Avatar.initialsOf(user.fullName),
          hasNotification: false,
          onTapAvatar: widget.onOpenProfile,
          summaries: agenda.hasValue && tasks.isNotEmpty ? _summaries(tasks) : const [],
        ),
        if (offline)
          OfflineBar(
            detail: cachedAt == null
                ? null
                : 'mostrando datos guardados ${DateLabels.relative(cachedAt)}',
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
          child: WeekStrip(
            days: days,
            onSelect: (i) => setState(() {
              _selectedDay = i;
              _filter = _AgendaFilter.all;
            }),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: CustomColors.primary,
            onRefresh: _refresh,
            child: _body(agenda, tasks),
          ),
        ),
      ],
    );
  }

  Widget _body(AsyncValue<DayAgenda> agenda, List<TaskSummary> tasks) {
    const padding = EdgeInsets.fromLTRB(16, 12, 16, 24);
    final title = _isToday ? 'Hoy' : DateLabels.longDate(_selectedDate);

    if (agenda.isLoading && !agenda.hasValue) {
      return ListView(
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _SectionTitle(title: title),
          for (var i = 0; i < 3; i++) ...[
            const Skeleton(width: double.infinity, height: 132, radius: CustomDimensions.radiusCard),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    if (agenda.hasError && !agenda.hasValue) {
      final noNetwork = agenda.error is DioException;
      return ListView(
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ErrorState(
            message: noNetwork
                ? 'Sin conexión y sin datos guardados de este día. Desliza hacia '
                      'abajo para intentar de nuevo.'
                : 'No pudimos cargar tu agenda.',
            onRetry: _refresh,
          ),
        ],
      );
    }

    if (tasks.isEmpty) {
      return ListView(
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _SectionTitle(title: title),
          EmptyState(
            icon: CustomIcons.today,
            title: _isToday ? 'Sin tareas hoy' : 'Sin tareas este día',
            message: _isToday
                ? 'Cuando te asignen limpiezas o mantenimientos aparecerán aquí, '
                      'también sin conexión.'
                : 'No tienes nada asignado para ${DateLabels.longDate(_selectedDate).toLowerCase()}.',
          ),
        ],
      );
    }

    final counts = {for (final f in _AgendaFilter.values) f: tasks.where((t) => _matches(t, f)).length};
    final visible = tasks.where((t) => _matches(t, _filter)).toList();

    return ListView(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _SectionTitle(
          title: title,
          trailing: '${tasks.length} ${tasks.length == 1 ? 'tarea' : 'tareas'}',
        ),
        FilterChips<_AgendaFilter>(
          padding: EdgeInsets.zero,
          options: [
            for (final f in _AgendaFilter.values)
              if (f == _AgendaFilter.all || counts[f]! > 0)
                FilterOption(value: f, label: _filterLabel(f), count: counts[f]),
          ],
          selected: {_filter},
          onChanged: (s) => setState(() => _filter = s.isEmpty ? _AgendaFilter.all : s.first),
        ),
        const SizedBox(height: 14),
        for (final task in visible) ...[
          AgendaTaskCard(
            task: task,
            unsynced: agenda.valueOrNull?.unsynced.contains(task.id) ?? false,
            onTap: () => context.push('/tasks/${task.id}', extra: task),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  static List<HeaderSummary> _summaries(List<TaskSummary> tasks) {
    final open = tasks.where((t) => t.status != TaskStatus.cancelled).length;
    final active = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final late = tasks.where((t) => t.showsLate).length;
    return [
      HeaderSummary(value: '$open', label: open == 1 ? 'Tarea' : 'Tareas'),
      HeaderSummary(value: '$active', label: 'En progreso', highlight: active > 0),
      HeaderSummary(value: '$late', label: late == 1 ? 'Retrasada' : 'Retrasadas'),
    ];
  }

  static bool _matches(TaskSummary t, _AgendaFilter f) => switch (f) {
    _AgendaFilter.all => true,
    _AgendaFilter.inProgress => t.status == TaskStatus.inProgress,
    _AgendaFilter.pending => t.status == TaskStatus.pending && !t.showsLate,
    _AgendaFilter.late => t.showsLate,
    _AgendaFilter.finished => t.status.isFinished,
  };

  static String _filterLabel(_AgendaFilter f) => switch (f) {
    _AgendaFilter.all => 'Todas',
    _AgendaFilter.inProgress => 'En progreso',
    _AgendaFilter.pending => 'Pendientes',
    _AgendaFilter.late => 'Retrasadas',
    _AgendaFilter.finished => 'Terminadas',
  };

  static WeekDay _weekDay(DateTime date, {required bool selected}) => WeekDay(
    weekday: DateLabels.weekdayInitial(date),
    day: '${date.day}',
    muted: date.weekday == DateTime.saturday || date.weekday == DateTime.sunday,
    selected: selected,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(title, style: CustomTypography.sectionTitle, semanticsLabel: title),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: CustomTypography.bodySmall.copyWith(color: CustomColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
