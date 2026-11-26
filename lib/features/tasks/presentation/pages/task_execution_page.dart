import 'dart:async';

import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/tasks/models/task_detail.dart';
import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:argos_app/features/tasks/presentation/providers/task_detail_controller.dart';
import 'package:argos_app/features/tasks/presentation/widgets/consumption_sheet.dart';
import 'package:argos_app/features/tasks/presentation/widgets/task_photos.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// B4 · Ejecución: checklist por secciones.
///
/// Cabecera fija con la propiedad, el cronómetro desde el inicio y el
/// avance; secciones plegables con cada punto (casilla de 32 dp, foto
/// requerida, miniaturas con su estado de subida y cámara). Marcar guarda al
/// instante en el teléfono y se envía en cuanto hay red. Mantener presionado
/// el título de una sección la marca completa.
class TaskExecutionPage extends ConsumerWidget {
  const TaskExecutionPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final load = ref.watch(taskDetailControllerProvider(taskId));
    final task = load.valueOrNull?.task;
    if (task == null) {
      return FormScaffold(
        title: 'Checklist',
        onBack: () => context.pop(),
        children: [
          if (load.hasError)
            ErrorState(
              message: errorMessage(load.error!),
              onRetry: () => ref.invalidate(taskDetailControllerProvider(taskId)),
            )
          else
            const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (task.summary.status != TaskStatus.inProgress) {
      // Ya se cerró (o la devolvieron/cancelaron): vuelve al detalle.
      return FormScaffold(
        title: task.summary.property.name,
        onBack: () => context.pop(),
        children: [
          EmptyState(
            icon: CustomIcons.done,
            title: task.summary.status.isFinished ? 'Tarea cerrada' : 'La tarea no está en curso',
            message: 'Vuelve al detalle para ver su estado.',
            actionLabel: 'Ver detalle',
            onAction: () => context.pop(),
          ),
        ],
      );
    }
    return _Execution(task: task);
  }
}

class _Execution extends ConsumerStatefulWidget {
  const _Execution({required this.task});

  final TaskDetail task;

  @override
  ConsumerState<_Execution> createState() => _ExecutionState();
}

class _ExecutionState extends ConsumerState<_Execution> {
  final _collapsed = <String>{};
  Timer? _tick;

  TaskDetail get task => widget.task;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    // Al abrir, solo la primera sección con pendientes queda abierta.
    final firstOpen = task.bySection.where((s) => s.$2.any((i) => !i.isDone)).firstOrNull?.$1;
    for (final (name, _) in task.bySection) {
      if (firstOpen != null && name != firstOpen) _collapsed.add(name);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  TaskDetailController get _ctl => ref.read(taskDetailControllerProvider(task.id).notifier);

  String _elapsed() {
    final started = task.summary.startedAt;
    if (started == null) return '0 min';
    final d = DateTime.now().difference(started);
    if (d.inMinutes < 60) return '${d.inMinutes.clamp(0, 59)} min';
    return '${d.inHours} h ${(d.inMinutes % 60).toString().padLeft(2, '0')} min';
  }

  Future<void> _toggle(ChecklistItem item, bool value) async {
    unawaited(HapticFeedback.selectionClick());
    try {
      await _ctl.setItem(item.id, isDone: value);
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    }
  }

  Future<void> _photo(ChecklistItem item, List<ItemPhoto> photos) async {
    final taken = await takeItemPhotos(
      context,
      ref,
      item: item,
      photos: photos,
      propertyCode: task.summary.property.code,
    );
    if (taken == 0 || !mounted) return;
    // Con la foto que faltaba, el punto queda marcado solo.
    final kind = nextKind(item, photos);
    final stillMissing = item.requiresBeforeAfter && kind == PhotoKind.before;
    if (!item.isDone && !stillMissing) await _toggle(item, true);
  }

  Future<void> _notes(ChecklistItem item) async {
    final text = await showArgosSheet<String>(
      context,
      builder: (_) => _NoteSheet(item: item),
    );
    if (text == null) return;
    await _ctl.setItem(item.id, notes: text);
  }

  @override
  Widget build(BuildContext context) {
    final s = task.summary;
    final total = task.items.length;
    final done = task.doneCount;
    return ArgosScaffold(
      padded: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              title: s.property.name,
              overline: '${s.property.code} · ${s.type.label}',
              elapsed: _elapsed(),
              done: done,
              total: total,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  for (final (name, items) in task.bySection) ...[
                    _SectionTitle(
                      name: name,
                      done: items.where((i) => i.isDone).length,
                      total: items.length,
                      collapsed: _collapsed.contains(name),
                      onTap: () => setState(
                        () => _collapsed.contains(name) ? _collapsed.remove(name) : _collapsed.add(name),
                      ),
                      onLongPress: () async {
                        final allDone = items.every((i) => i.isDone);
                        final blocked = !allDone && items.any((i) => i.needsPhotos && !i.isDone);
                        if (blocked) {
                          showToast(context, 'Hay puntos con foto pendiente en $name.');
                          return;
                        }
                        unawaited(HapticFeedback.mediumImpact());
                        await _ctl.setSection(name, !allDone);
                      },
                    ),
                    if (!_collapsed.contains(name))
                      for (final item in items)
                        _ItemRow(
                          item: item,
                          onToggle: (v) => _toggle(item, v),
                          onPhoto: (photos) => _photo(item, photos),
                          onNotes: () => _notes(item),
                        ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            _Footer(
              onSupplies: s.type.isCleaning
                  ? () => showConsumptionSheet(context, task)
                  : null,
              onClose: () => context.push('/tasks/${task.id}/close'),
              closeLabel: s.type.isCleaning ? 'Cerrar limpieza' : 'Cerrar ${s.type.label.toLowerCase()}',
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.overline,
    required this.elapsed,
    required this.done,
    required this.total,
    required this.onBack,
  });

  final String title;
  final String overline;
  final String elapsed;
  final int done;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomColors.primary,
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Volver',
                icon: const Icon(CustomIcons.arrowBack, color: Colors.white),
                onPressed: onBack,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overline.toUpperCase(),
                      style: CustomTypography.label.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CustomTypography.sectionTitle.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                SummaryChip(value: elapsed, label: 'En curso'),
                const SizedBox(width: 10),
                SummaryChip(
                  value: '$done/$total',
                  label: 'Puntos',
                  valueColor: done == total ? CustomColors.secondary : Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ProgressBar(
              value: total == 0 ? 0 : done / total,
              trackColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.name,
    required this.done,
    required this.total,
    required this.collapsed,
    required this.onTap,
    required this.onLongPress,
  });

  final String name;
  final int done;
  final int total;
  final bool collapsed;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final complete = done == total;
    return Semantics(
      button: true,
      hint: 'Mantén presionado para marcar toda la sección',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(name, style: CustomTypography.cardTitle)),
                  Text(
                    '$done/$total',
                    style: CustomTypography.data.copyWith(
                      color: complete ? CustomColors.success : CustomColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: collapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(CustomIcons.expand, color: CustomColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ProgressBar(
                value: total == 0 ? 0 : done / total,
                height: 4,
                fillColor: complete ? CustomColors.success : CustomColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    required this.item,
    required this.onToggle,
    required this.onPhoto,
    required this.onNotes,
  });

  final ChecklistItem item;
  final ValueChanged<bool> onToggle;
  final ValueChanged<List<ItemPhoto>> onPhoto;
  final VoidCallback onNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploads = ref.watch(entityUploadsProvider(checklistEntity, item.id)).valueOrNull ?? const [];
    final photos = mergePhotos(item, uploads);
    final missing = missingPhotos(item, photos);
    final description = [
      if (item.requiresBeforeAfter)
        missing == 0
            ? 'Antes y después listos'
            : 'Falta foto ${nextKind(item, photos).label.toLowerCase()}',
      if (item.notes != null && item.notes!.isNotEmpty) 'Nota: ${item.notes}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onLongPress: onNotes,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: missing > 0 && !item.isDone ? CustomColors.warningSoft : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: ChecklistItemRow(
            label: item.text,
            checked: item.isDone,
            description: description.isEmpty ? null : description,
            requiresPhoto: item.needsPhotos,
            photos: [
              for (final p in photos)
                PhotoItem(
                  image: photoImage(ref, p),
                  status: photoStatus(p),
                  progress: p.local?.progress,
                  onRetry: p.failed ? () => ref.read(uploadQueueProvider).retry(p.local!.id) : null,
                ),
            ],
            onChanged: missing > 0 && !item.isDone ? null : onToggle,
            onTakePhoto: () => onPhoto(photos),
            onOpenPhoto: (i) => showPhotoViewer(context, ref, photos[i]),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onClose, required this.closeLabel, this.onSupplies});

  final VoidCallback onClose;
  final String closeLabel;
  final VoidCallback? onSupplies;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: CustomColors.surface,
        border: Border(top: BorderSide(color: CustomColors.border)),
      ),
      child: Row(
        children: [
          if (onSupplies != null) ...[
            Expanded(flex: 2, child: SecondaryButton(label: 'Insumos', onPressed: onSupplies)),
            const SizedBox(width: 12),
          ],
          Expanded(flex: 3, child: PrimaryButton(label: closeLabel, onPressed: onClose)),
        ],
      ),
    );
  }
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.item});

  final ChecklistItem item;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _text = TextEditingController(text: widget.item.notes ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    title: 'Nota del punto',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.item.text, style: CustomTypography.bodySmall),
        const SizedBox(height: 12),
        AppTextField(controller: _text, hintText: 'Ej.: falta un foco en la lámpara', maxLines: 3),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Guardar nota',
          onPressed: () => Navigator.of(context).pop(_text.text.trim()),
        ),
      ],
    ),
  );
}
