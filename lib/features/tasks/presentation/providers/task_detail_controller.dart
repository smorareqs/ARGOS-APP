import 'dart:async';

import 'package:argos_app/features/tasks/data/repositories/tasks_repository.dart';
import 'package:argos_app/features/tasks/models/task_detail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_detail_controller.g.dart';

/// Estado de una tarea abierta: se recarga sola cuando un cambio llega al
/// servidor, y cada acción la actualiza al instante (también sin red).
@riverpod
class TaskDetailController extends _$TaskDetailController {
  @override
  Future<TaskLoad> build(String id) {
    final repo = ref.watch(tasksRepositoryProvider);
    Timer? debounce;
    final sub = repo.changes.where((t) => t == id).listen((_) {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 400), _reload);
    });
    ref.onDispose(() {
      debounce?.cancel();
      sub.cancel();
    });
    return repo.detail(id);
  }

  TasksRepository get _repo => ref.read(tasksRepositoryProvider);

  Future<void> _reload() async {
    try {
      final fresh = await _repo.detail(id);
      state = AsyncData(fresh);
    } catch (_) {
      // Se queda con lo que hay; la próxima vez lo intenta de nuevo.
    }
  }

  Future<void> refresh() => _reload();

  TaskDetail? get _task => state.valueOrNull?.task;

  void _set(TaskDetail task) {
    final cur = state.valueOrNull;
    state = AsyncData(
      TaskLoad(task: task, cachedAt: cur?.cachedAt, pending: (cur?.pending ?? 0) + 1),
    );
  }

  Future<void> start({required double lat, required double lng}) async {
    final t = _task;
    if (t == null) return;
    _set(await _repo.start(t, lat: lat, lng: lng));
  }

  Future<void> setItem(String itemId, {bool? isDone, String? notes}) async {
    final t = _task;
    if (t == null) return;
    _set(await _repo.setItem(t, itemId, isDone: isDone, notes: notes));
  }

  /// Marca o desmarca todos los puntos de una sección.
  Future<void> setSection(String section, bool done) async {
    var t = _task;
    if (t == null) return;
    for (final item in t.items.where((i) => i.section == section && i.isDone != done)) {
      t = await _repo.setItem(t!, item.id, isDone: done);
    }
    if (t != null) _set(t);
  }

  Future<void> addConsumptions(Map<String, double> used) async {
    final t = _task;
    if (t == null || used.values.every((v) => v <= 0)) return;
    _set(await _repo.addConsumptions(t, used));
  }

  Future<void> complete({
    required double lat,
    required double lng,
    String? notes,
    required List<CustodyReturn> custody,
  }) async {
    final t = _task;
    if (t == null) return;
    _set(await _repo.complete(t, lat: lat, lng: lng, notes: notes, custody: custody));
  }

  /// Validar o devolver (supervisor). Necesita conexión.
  Future<void> decide({required bool approve, String? note}) async {
    final t = _task;
    if (t == null) return;
    final fresh = await _repo.decide(t, approve: approve, note: note);
    state = AsyncData(TaskLoad(task: fresh));
  }
}
