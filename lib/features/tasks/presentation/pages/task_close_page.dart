import 'dart:async';

import 'package:argos_app/core/location/location_service.dart';
import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/tasks/data/repositories/tasks_repository.dart';
import 'package:argos_app/features/tasks/models/task_detail.dart';
import 'package:argos_app/features/tasks/presentation/providers/task_detail_controller.dart';
import 'package:argos_app/features/tasks/presentation/widgets/task_photos.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// B7 · Cierre: requisitos (checklist, fotos, ubicación) y conciliación de
/// custodia (devuelvo, consumí, me quedo). Lo que no cuadra se marca en
/// ámbar y queda como diferencia. Sin red se guarda y se cierra solo al
/// reconectar (después de subir las fotos).
class TaskClosePage extends ConsumerStatefulWidget {
  const TaskClosePage({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskClosePage> createState() => _TaskClosePageState();
}

class _Line {
  _Line(this.c) : kept = c.quantity.floor();

  final CustodyLine c;
  int returned = 0;
  int consumed = 0;
  int kept;

  int get custody => c.quantity.floor();
  int get difference => custody - returned - consumed - kept;
}

class _TaskClosePageState extends ConsumerState<TaskClosePage> {
  GeoPoint? _point;
  String? _locationError;
  var _locating = true;
  var _sending = false;
  List<_Line>? _lines;
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_locate());
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final p = await ref.read(locationServiceProvider).current();
      if (mounted) setState(() => _point = p);
    } on LocationException catch (e) {
      if (mounted) setState(() => _locationError = e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit(TaskDetail task) async {
    final point = _point;
    if (point == null) return;
    setState(() => _sending = true);
    final lines = _lines ?? const [];
    final gaps = [
      for (final l in lines)
        if (l.difference > 0) '${l.c.name}: faltan ${l.difference}',
    ];
    final notes = [
      _notes.text.trim(),
      if (gaps.isNotEmpty) 'Diferencias: ${gaps.join('; ')}',
    ].where((t) => t.isNotEmpty).join('\n');
    try {
      await ref.read(taskDetailControllerProvider(task.id).notifier).complete(
        lat: point.lat,
        lng: point.lng,
        notes: notes.isEmpty ? null : notes,
        custody: [
          for (final l in lines)
            CustodyReturn(
              itemId: l.c.itemId,
              returned: l.returned.toDouble(),
              consumed: l.consumed.toDouble(),
              // Las fracciones (litros) se quedan con la persona.
              kept: l.kept + (l.c.quantity - l.custody),
            ),
        ],
      );
      if (!mounted) return;
      context.pushReplacement('/tasks/${task.id}/done', extra: gaps.length);
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final load = ref.watch(taskDetailControllerProvider(widget.taskId));
    final task = load.valueOrNull?.task;
    if (task == null) {
      return FormScaffold(
        title: 'Antes de cerrar',
        onBack: () => context.pop(),
        children: const [Center(child: CircularProgressIndicator())],
      );
    }
    _lines ??= [for (final c in task.custody) _Line(c)];
    final lines = _lines!;

    // Fotos que faltan, por sección.
    final missingBySection = <String, int>{};
    for (final item in task.items.where((i) => i.needsPhotos)) {
      final uploads = ref.watch(entityUploadsProvider(checklistEntity, item.id)).valueOrNull ?? const [];
      final missing = missingPhotos(item, mergePhotos(item, uploads));
      if (missing > 0) missingBySection.update(item.section, (v) => v + missing, ifAbsent: () => missing);
    }
    final pendingItems = task.items.where((i) => !i.isDone).toList();
    final missingPhotosTotal = missingBySection.values.fold<int>(0, (a, b) => a + b);
    final overCounted = lines.where((l) => l.difference < 0).toList();
    final gaps = lines.where((l) => l.difference > 0).length;

    final reason = pendingItems.isNotEmpty
        ? 'Faltan ${pendingItems.length} ${pendingItems.length == 1 ? 'punto' : 'puntos'} del checklist'
        : missingPhotosTotal > 0
        ? 'Faltan $missingPhotosTotal ${missingPhotosTotal == 1 ? 'foto' : 'fotos'} en ${missingBySection.keys.join(', ')}'
        : _point == null
        ? (_locating ? 'Obteniendo tu ubicación…' : 'Falta tu ubicación')
        : overCounted.isNotEmpty
        ? 'Revisa ${overCounted.first.c.name}: declaraste más de lo que tienes'
        : null;

    final auth = ref.watch(sessionControllerProvider);
    final offline = auth is AuthSignedIn && auth.offline;
    final verb = task.summary.type.isCleaning ? 'limpieza' : task.summary.type.label.toLowerCase();

    return FormScaffold(
      title: 'Antes de cerrar',
      subtitle: '${task.summary.property.name} · ${task.summary.type.label}',
      onBack: () => context.pop(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reason != null) ...[
            Text(
              reason,
              textAlign: TextAlign.center,
              style: CustomTypography.bodySmall.copyWith(color: CustomColors.warning),
            ),
            const SizedBox(height: 10),
          ],
          PrimaryButton(
            label: offline ? 'Guardar para cerrar al reconectar' : 'Confirmar y cerrar $verb',
            isLoading: _sending,
            onPressed: reason != null || _sending ? null : () => _submit(task),
          ),
        ],
      ),
      children: [
        AppCard(
          child: Column(
            children: [
              _Requirement(
                ok: pendingItems.isEmpty,
                title: 'Checklist completo',
                detail: pendingItems.isEmpty
                    ? '${task.items.length} de ${task.items.length} puntos'
                    : 'Faltan ${pendingItems.length}: ${pendingItems.take(2).map((i) => i.text).join(', ')}'
                          '${pendingItems.length > 2 ? '…' : ''}',
              ),
              _Requirement(
                ok: missingPhotosTotal == 0,
                title: 'Fotos requeridas',
                detail: missingPhotosTotal == 0
                    ? 'Completas (se suben solas)'
                    : missingBySection.entries.map((e) => '${e.value} en ${e.key}').join(' · '),
              ),
              _Requirement(
                ok: _point != null,
                loading: _locating,
                title: 'Ubicación',
                detail: _point != null
                    ? 'Obtenida'
                    : _locating
                    ? 'Buscando señal…'
                    : _locationError ?? 'No disponible',
                action: _point == null && !_locating
                    ? TextButton(onPressed: _locate, child: const Text('Reintentar'))
                    : null,
              ),
              _Requirement(
                ok: overCounted.isEmpty,
                title: 'Custodia conciliada',
                detail: lines.isEmpty
                    ? 'No tienes artículos en custodia'
                    : gaps == 0
                    ? 'Todo cuadra'
                    : '$gaps ${gaps == 1 ? 'diferencia se registrará' : 'diferencias se registrarán'}',
                warn: gaps > 0,
                last: true,
              ),
            ],
          ),
        ),
        if (lines.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text('Tu custodia', style: CustomTypography.sectionTitle)),
              TextButton(
                onPressed: () => setState(() {
                  for (final l in lines) {
                    l
                      ..returned = l.custody
                      ..consumed = 0
                      ..kept = 0;
                  }
                }),
                child: const Text('Devolver todo'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Indica qué devuelves a la bodega, qué gastaste y con qué te quedas para la '
            'siguiente tarea. Los blancos y llaves no se consumen.',
            style: CustomTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final l in lines) ...[
            QuantityRow(
              name: l.c.name,
              unit: l.c.unit,
              custody: l.custody,
              returned: l.returned,
              consumed: l.consumed,
              kept: l.kept,
              onReturnedChanged: (v) => setState(() => l.returned = v),
              onConsumedChanged: l.c.returnable ? null : (v) => setState(() => l.consumed = v),
              onKeptChanged: (v) => setState(() => l.kept = v),
            ),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 12),
        Text('Notas para el supervisor', style: CustomTypography.cardTitle),
        const SizedBox(height: 8),
        AppTextField(
          controller: _notes,
          hintText: 'Opcional: algo que deba saber',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({
    required this.ok,
    required this.title,
    required this.detail,
    this.loading = false,
    this.warn = false,
    this.last = false,
    this.action,
  });

  final bool ok;
  final bool loading;
  final bool warn;
  final bool last;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = loading
        ? CustomColors.textMuted
        : !ok
        ? CustomColors.error
        : warn
        ? CustomColors.warning
        : CustomColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: CustomColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(5),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    ok ? (warn ? CustomIcons.incident : CustomIcons.check) : CustomIcons.clear,
                    color: color,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CustomTypography.cardTitle),
                const SizedBox(height: 2),
                Text(detail, style: CustomTypography.bodySmall),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// B8 · Limpieza cerrada: check animado, duración, fotos y diferencias. Se
/// cierra sola a los 4 s.
class TaskClosedPage extends ConsumerStatefulWidget {
  const TaskClosedPage({super.key, required this.taskId, this.discrepancies = 0});

  final String taskId;
  final int discrepancies;

  @override
  ConsumerState<TaskClosedPage> createState() => _TaskClosedPageState();
}

class _TaskClosedPageState extends ConsumerState<TaskClosedPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), _home);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _home() {
    if (mounted) context.go('/home/today');
  }

  @override
  Widget build(BuildContext context) {
    final load = ref.watch(taskDetailControllerProvider(widget.taskId)).valueOrNull;
    final s = load?.task.summary;
    final pending = (load?.pending ?? 0) > 0;
    final started = s?.startedAt;
    final minutes = started == null ? null : DateTime.now().difference(started).inMinutes;
    final duration = minutes == null
        ? null
        : minutes < 60
        ? '$minutes min'
        : '${minutes ~/ 60} h ${minutes % 60} min';
    final photos = load?.task.items.fold<int>(0, (a, i) => a + i.photos.length) ?? 0;
    final local = [
      for (final item in load?.task.items ?? const <ChecklistItem>[])
        ...?ref.watch(entityUploadsProvider(checklistEntity, item.id)).valueOrNull,
    ].length;
    final photoCount = local > photos ? local : photos;

    return Scaffold(
      backgroundColor: CustomColors.primary,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _timer?.cancel(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: const BoxDecoration(color: CustomColors.secondary, shape: BoxShape.circle),
                    child: const Icon(CustomIcons.done, size: 64, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  pending ? 'Lista para cerrar' : '${s?.type.label ?? 'Tarea'} cerrada',
                  textAlign: TextAlign.center,
                  style: CustomTypography.pageTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  [
                    if (s != null) s.property.name,
                    ?duration,
                    if (photoCount > 0) '$photoCount ${photoCount == 1 ? 'foto' : 'fotos'}',
                  ].join(' · '),
                  textAlign: TextAlign.center,
                  style: CustomTypography.body.copyWith(color: Colors.white70),
                ),
                if (pending) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Sin conexión: se envía sola al reconectar, después de subir las fotos.',
                    textAlign: TextAlign.center,
                    style: CustomTypography.bodySmall.copyWith(color: Colors.white),
                  ),
                ],
                if (widget.discrepancies > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: CustomColors.warningSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.discrepancies == 1
                          ? 'Se registró 1 diferencia de inventario'
                          : 'Se registraron ${widget.discrepancies} diferencias de inventario',
                      style: CustomTypography.bodySmall.copyWith(color: CustomColors.warning),
                    ),
                  ),
                ],
                const Spacer(),
                PrimaryButton(label: 'Volver a Hoy', onPressed: _home),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
