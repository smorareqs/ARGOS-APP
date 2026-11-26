import 'dart:async';

import 'package:argos_app/core/location/location_service.dart';
import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/tasks/data/repositories/tasks_repository.dart';
import 'package:argos_app/features/tasks/models/task_detail.dart';
import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:argos_app/features/tasks/presentation/providers/task_detail_controller.dart';
import 'package:argos_app/features/tasks/presentation/widgets/agenda_task_card.dart';
import 'package:argos_app/features/tasks/presentation/widgets/reschedule_sheet.dart';
import 'package:argos_app/features/tasks/presentation/widgets/task_photos.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// B3 · Detalle de tarea y C3 · Validar (supervisor).
///
/// Cabecera con propiedad, estado y ventana; dirección con "Cómo llegar";
/// acceso (solo el día de la tarea, se muestra 30 s); reserva; notas;
/// avance del checklist; insumos, diferencias y línea de tiempo. Botón fijo
/// "Iniciar" / "Continuar" para quien la ejecuta y "Validar" / "Devolver"
/// para el supervisor cuando está terminada.
class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({super.key, required this.taskId, this.preview});

  final String taskId;

  /// Lo que ya se sabe de la tarea (de la agenda) mientras carga.
  final TaskSummary? preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final load = ref.watch(taskDetailControllerProvider(taskId));
    return load.when(
      data: (data) => TaskDetailView(
        load: data,
        onRefresh: () => ref.read(taskDetailControllerProvider(taskId).notifier).refresh(),
      ),
      loading: () => _Loading(preview: preview),
      error: (e, _) => FormScaffold(
        title: preview?.property.name ?? 'Tarea',
        onBack: () => context.pop(),
        children: [
          ErrorState(
            message: e is DioException
                ? 'Sin conexión y sin una copia guardada de esta tarea.'
                : errorMessage(e),
            onRetry: () => ref.invalidate(taskDetailControllerProvider(taskId)),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({this.preview});

  final TaskSummary? preview;

  @override
  Widget build(BuildContext context) {
    final p = preview;
    return DetailScaffold(
      overline: p == null ? null : '${p.property.code} · ${p.type.label}',
      title: p?.property.name ?? 'Cargando…',
      subtitle: p?.windowLabel,
      onBack: () => context.pop(),
      children: [
        for (var i = 0; i < 3; i++) ...[
          const Skeleton(width: double.infinity, height: 96, radius: CustomDimensions.radiusCard),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// El contenido del detalle (separado para el catálogo de componentes).
class TaskDetailView extends ConsumerStatefulWidget {
  const TaskDetailView({super.key, required this.load, this.onRefresh, this.today});

  final TaskLoad load;
  final Future<void> Function()? onRefresh;

  /// Fecha de referencia (por defecto hoy).
  final DateTime? today;

  @override
  ConsumerState<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends ConsumerState<TaskDetailView> {
  var _busy = false;

  TaskDetail get task => widget.load.task;
  TaskSummary get s => task.summary;

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final point = await ref.read(locationServiceProvider).current();
      await ref
          .read(taskDetailControllerProvider(task.id).notifier)
          .start(lat: point.lat, lng: point.lng);
      if (mounted) unawaited(context.push('/tasks/${task.id}/run'));
    } on LocationException catch (e) {
      if (!mounted) return;
      showToast(context, e.message);
      if (e.openSettings) unawaited(ref.read(locationServiceProvider).openSettings());
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(bool approve) async {
    String? note;
    if (!approve) {
      note = await _askReason(context);
      if (note == null) return;
    } else {
      final ok = await showConfirmSheet(
        context,
        title: 'Validar ${s.type.label.toLowerCase()}',
        message: '${s.property.name} quedará validada y contará para las métricas de '
            '${s.assigneeName ?? 'quien la hizo'}.',
        confirmLabel: 'Validar',
      );
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(taskDetailControllerProvider(task.id).notifier)
          .decide(approve: approve, note: note);
      if (mounted) showToast(context, approve ? 'Tarea validada.' : 'Tarea devuelta con tu motivo.');
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _directions() async {
    final p = s.property;
    final destination = p.lat != null && p.lng != null
        ? '${p.lat},${p.lng}'
        : Uri.encodeComponent('${p.name}, ${p.address}');
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      showToast(context, 'No se pudo abrir la app de mapas.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusVariant) = taskStatusBadge(s);
    final window = s.windowLabel;
    final dateLabel = DateLabels.longDate(s.scheduledDate);
    final now = widget.today ?? DateTime.now();
    final isToday = DateUtils.isSameDay(s.scheduledDate, now);
    final returnedNote = s.status == TaskStatus.returned
        ? s.timeline.lastWhere((e) => e.type == 'returned', orElse: () => _noEvent).detail
        : null;

    final footer = _footer();
    return DetailScaffold(
      overline: '${s.property.code} · ${s.type.label}${s.number > 0 ? ' · #${s.number}' : ''}',
      title: s.property.name,
      subtitle: window == null ? dateLabel : '$dateLabel · $window',
      status: StatusBadge(label: statusLabel, variant: statusVariant),
      banner: _banner(returnedNote),
      onBack: () => context.pop(),
      actions: [
        if (task.canManage && s.status.isOpen)
          AppIconButton(
            icon: CustomIcons.swap,
            semanticLabel: 'Reasignar o reprogramar',
            onPressed: () => showRescheduleSheet(context, task.summary),
          ),
      ],
      footer: footer,
      children: [
        if (widget.load.cachedAt != null || widget.load.pending > 0) ...[
          _SyncNote(load: widget.load),
          const SizedBox(height: 12),
        ],
        _InfoCard(
          icon: CustomIcons.location,
          label: 'Dirección',
          action: TertiaryButton(label: 'Cómo llegar', isExpanded: false, onPressed: _directions),
          child: Text(
            [s.property.address, if (s.property.buildingName != null) s.property.buildingName!]
                .where((t) => t.isNotEmpty)
                .toSet()
                .join(' · '),
            style: CustomTypography.body,
          ),
        ),
        if (isToday && (task.canExecute || task.canManage) && s.status != TaskStatus.cancelled) ...[
          const SizedBox(height: 12),
          _AccessCard(propertyId: s.property.id),
        ],
        if (s.reservationCode != null) ...[
          const SizedBox(height: 12),
          _InfoCard(
            icon: CustomIcons.reservations,
            label: 'Reserva asociada',
            child: Text(
              s.type == TaskType.checkoutCleaning
                  ? 'Salida de la reserva ${s.reservationCode}'
                  : 'Reserva ${s.reservationCode}',
              style: CustomTypography.body,
            ),
          ),
        ],
        if (s.notes != null && s.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoCard(
            icon: CustomIcons.notes,
            label: 'Notas del administrador',
            child: Text(s.notes!, style: CustomTypography.body),
          ),
        ],
        if (task.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ChecklistPreview(task: task),
        ],
        if (s.consumption.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoCard(
            icon: CustomIcons.equipment,
            label: 'Insumos usados',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final c in s.consumption)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${c.item} · ${_qty(c.qty)} ${c.unit}', style: CustomTypography.body),
                  ),
              ],
            ),
          ),
        ],
        if (s.discrepancy != null) ...[
          const SizedBox(height: 12),
          _InfoCard(
            icon: CustomIcons.incident,
            label: 'Diferencias de inventario',
            tone: CustomColors.warning,
            child: Text(s.discrepancy!, style: CustomTypography.body),
          ),
        ],
        if (task.canManage && (s.status == TaskStatus.done || s.status == TaskStatus.validated))
          ..._evidence(),
        const SizedBox(height: 28),
        Text('Línea de tiempo', style: CustomTypography.sectionTitle),
        const SizedBox(height: 16),
        ..._timeline(),
      ],
    );
  }

  Widget? _banner(String? returnedNote) {
    if (s.status == TaskStatus.returned) {
      return DetailBanner(
        icon: CustomIcons.retry,
        message: returnedNote == null ? 'Devuelta para corregir' : 'Devuelta: $returnedNote',
      );
    }
    if (s.showsLate && s.windowStart != null) {
      return DetailBanner(
        message: s.status == TaskStatus.pending
            ? 'Debió iniciar a las ${s.windowStart}'
            : 'Debió terminar a las ${s.windowEnd}',
      );
    }
    if (s.status == TaskStatus.cancelled) {
      return const DetailBanner(
        icon: CustomIcons.cancel,
        message: 'Cancelada',
        background: CustomColors.neutralSoft,
        foreground: CustomColors.textBody,
      );
    }
    return null;
  }

  Widget? _footer() {
    if (task.canExecute) {
      final verb = s.type.isCleaning ? 'limpieza' : s.type.label.toLowerCase();
      switch (s.status) {
        case TaskStatus.pending:
        case TaskStatus.returned:
          return PrimaryButton(
            label: s.status == TaskStatus.returned ? 'Retomar $verb' : 'Iniciar $verb',
            isLoading: _busy,
            onPressed: _busy ? null : _start,
          );
        case TaskStatus.inProgress:
          return PrimaryButton(
            label: 'Continuar',
            trailingIcon: CustomIcons.arrowForward,
            onPressed: () => context.push('/tasks/${task.id}/run'),
          );
        default:
          break;
      }
    }
    if (task.canManage && s.status == TaskStatus.done) {
      return Row(
        children: [
          Expanded(
            child: SecondaryButton(label: 'Devolver', onPressed: _busy ? null : () => _decide(false)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Validar',
              isLoading: _busy,
              onPressed: _busy ? null : () => _decide(true),
            ),
          ),
        ],
      );
    }
    return null;
  }

  /// C3: fotos por sección para revisar antes de validar.
  List<Widget> _evidence() {
    final withPhotos = task.items.where((i) => i.photos.isNotEmpty).toList();
    return [
      const SizedBox(height: 28),
      Text('Fotos', style: CustomTypography.sectionTitle),
      const SizedBox(height: 12),
      if (withPhotos.isEmpty)
        Text('Esta tarea no tiene fotos.', style: CustomTypography.bodySmall)
      else
        for (final item in withPhotos) _ReviewPhotos(item: item),
      if (s.timeline.any((e) => e.type == 'finished') && task.raw['completion_notes'] is String) ...[
        const SizedBox(height: 12),
        _InfoCard(
          icon: CustomIcons.notes,
          label: 'Notas de ${s.assigneeName ?? 'quien la hizo'}',
          child: Text('${task.raw['completion_notes']}', style: CustomTypography.body),
        ),
      ],
    ];
  }

  List<Widget> _timeline() {
    final events = s.timeline.isNotEmpty
        ? [
            for (final e in s.timeline)
              (e.text, hhmm(e.at), _eventIcon(e.type), _eventTone(e.type), _eventDetail(e)),
          ]
        : [
            (
              'Programada',
              s.windowStart ?? '',
              CustomIcons.today,
              TimelineTone.neutral,
              s.windowLabel == null ? null : 'Ventana ${s.windowLabel}',
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

  static String? _eventDetail(TaskEvent e) {
    final parts = [if (e.actor.isNotEmpty) e.actor, if (e.detail != null) e.detail!];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static IconData _eventIcon(String type) => switch (type) {
    'started' => CustomIcons.play,
    'finished' => CustomIcons.done,
    'validated' => CustomIcons.doneAll,
    'returned' => CustomIcons.retry,
    'late' => CustomIcons.pending,
    'cancelled' => CustomIcons.cancel,
    'consumption' => CustomIcons.equipment,
    'discrepancy' => CustomIcons.incident,
    'assigned' || 'rescheduled' => CustomIcons.swap,
    _ => CustomIcons.today,
  };

  static TimelineTone _eventTone(String type) => switch (type) {
    'started' => TimelineTone.info,
    'finished' || 'validated' => TimelineTone.success,
    'returned' || 'late' || 'discrepancy' => TimelineTone.warning,
    _ => TimelineTone.neutral,
  };
}

final _noEvent = TaskEvent(at: DateTime(2000), type: '', text: '', actor: '');

String _qty(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);

Future<String?> _askReason(BuildContext context) => showArgosSheet<String>(
  context,
  builder: (_) => const _ReasonSheet(),
);

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet();

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Devolver para corregir',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quien la hizo verá tu motivo y podrá retomarla.',
            style: CustomTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _text,
            hintText: 'Motivo, p. ej.: falta la foto del baño',
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Devolver',
            onPressed: _text.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_text.text.trim()),
          ),
        ],
      ),
    );
  }
}

class _SyncNote extends StatelessWidget {
  const _SyncNote({required this.load});

  final TaskLoad load;

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (load.cachedAt != null) 'Copia guardada ${DateLabels.relative(load.cachedAt!)}',
      if (load.pending > 0)
        load.pending == 1 ? '1 cambio por enviar' : '${load.pending} cambios por enviar',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CustomColors.neutralSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(CustomIcons.uploadQueued, size: 18, color: CustomColors.textBody),
          const SizedBox(width: 10),
          Expanded(child: Text(parts.join(' · '), style: CustomTypography.bodySmall)),
        ],
      ),
    );
  }
}

/// Acceso: se pide al servidor solo al tocar y se oculta a los 30 s.
class _AccessCard extends ConsumerStatefulWidget {
  const _AccessCard({required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<_AccessCard> createState() => _AccessCardState();
}

class _AccessCardState extends ConsumerState<_AccessCard> {
  String? _text;
  var _left = 0;
  var _loading = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _reveal() async {
    setState(() => _loading = true);
    try {
      final text = await ref.read(tasksRepositoryProvider).accessInfo(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _text = text.trim().isEmpty ? 'Sin información de acceso registrada.' : text;
        _left = 30;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _left--);
        if (_left <= 0) {
          t.cancel();
          setState(() => _text = null);
        }
      });
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is DioException ? 'Los códigos solo se ven con conexión.' : errorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    return _InfoCard(
      icon: CustomIcons.key,
      label: 'Acceso',
      action: text == null
          ? TertiaryButton(
              label: _loading ? 'Cargando…' : 'Ver códigos',
              isExpanded: false,
              onPressed: _loading ? null : _reveal,
            )
          : Text('${_left}s', style: CustomTypography.data.copyWith(color: CustomColors.textSecondary)),
      child: text == null
          ? Text(
              'Llaves, códigos y wifi. Se muestran 30 segundos y la consulta queda registrada.',
              style: CustomTypography.bodySmall,
            )
          : SelectableText(text, style: CustomTypography.mono.copyWith(height: 1.6)),
    );
  }
}

class _ChecklistPreview extends StatelessWidget {
  const _ChecklistPreview({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final sections = task.bySection;
    return _InfoCard(
      icon: CustomIcons.activities,
      label: 'Checklist',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${task.doneCount} de ${task.items.length} puntos',
            style: CustomTypography.cardTitle,
          ),
          const SizedBox(height: 10),
          ProgressBar(value: task.items.isEmpty ? 0 : task.doneCount / task.items.length),
          const SizedBox(height: 14),
          for (final (name, items) in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    items.every((i) => i.isDone) ? CustomIcons.check : CustomIcons.pending,
                    size: 16,
                    color: items.every((i) => i.isDone) ? CustomColors.success : CustomColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name, style: CustomTypography.bodySmall)),
                  Text(
                    '${items.where((i) => i.isDone).length}/${items.length}',
                    style: CustomTypography.data.copyWith(color: CustomColors.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewPhotos extends ConsumerWidget {
  const _ReviewPhotos({required this.item});

  final ChecklistItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploads = ref.watch(entityUploadsProvider(checklistEntity, item.id)).valueOrNull ?? const [];
    final photos = mergePhotos(item, uploads);
    final before = photos.where((p) => p.kind == PhotoKind.before).firstOrNull;
    final after = photos.where((p) => p.kind == PhotoKind.after).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${item.section} · ${item.text}', style: CustomTypography.label),
          const SizedBox(height: 8),
          if (before != null && after != null)
            BeforeAfterPair(before: photoImage(ref, before), after: photoImage(ref, after))
          else
            PhotoGrid(
              photos: [
                for (final p in photos) PhotoItem(image: photoImage(ref, p), status: photoStatus(p)),
              ],
              onOpen: (i) => showPhotoViewer(context, ref, photos[i]),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.child,
    this.action,
    this.tone = CustomColors.primary,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? action;
  final Color tone;

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
              color: tone == CustomColors.primary ? CustomColors.tealWashed : CustomColors.warningSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: tone),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(label.toUpperCase(), style: CustomTypography.label)),
                    ?action,
                  ],
                ),
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
