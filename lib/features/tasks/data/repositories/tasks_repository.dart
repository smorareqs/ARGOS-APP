import 'dart:async';
import 'dart:convert';

import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/core/outbox/outbox.dart';
import 'package:argos_app/core/outbox/outbox_providers.dart';
import 'package:argos_app/features/tasks/data/datasources/tasks_remote_datasource.dart';
import 'package:argos_app/features/tasks/models/task_detail.dart';
import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasks_repository.g.dart';

/// Agenda de un día, con de dónde salió.
class DayAgenda {
  const DayAgenda({required this.tasks, this.cachedAt, this.unsynced = const {}});

  final List<TaskSummary> tasks;

  /// Si no es null, no hubo conexión y es la copia guardada a esa hora.
  final DateTime? cachedAt;

  /// Tareas con cambios guardados en el teléfono que aún no llegan.
  final Set<String> unsynced;

  bool get fromCache => cachedAt != null;
}

/// Una tarea con su checklist y de dónde salió.
class TaskLoad {
  const TaskLoad({required this.task, this.cachedAt, this.pending = 0});

  final TaskDetail task;

  /// Si no es null, no hubo conexión y es la copia guardada.
  final DateTime? cachedAt;

  /// Cambios aún sin enviar.
  final int pending;
}

/// Una línea de la conciliación de custodia al cerrar.
class CustodyReturn {
  const CustodyReturn({
    required this.itemId,
    required this.returned,
    required this.consumed,
    required this.kept,
  });

  final String itemId;
  final double returned;
  final double consumed;
  final double kept;

  Map<String, Object> toJson() => {
    'item_id': itemId,
    'returned': returned,
    'consumed': consumed,
    'kept': kept,
  };
}

/// Tareas con caché para usarlas sin conexión (fase02 §5, ux-ui.md B1–B8).
///
/// Lecturas: del servidor, y si no hay red la última copia guardada.
/// Ejecución (iniciar, checklist, insumos, cerrar): se aplica al instante en
/// la copia local y se guarda en la cola [Outbox], que la envía en orden en
/// cuanto hay conexión. El cierre espera a que suban las fotos.
class TasksRepository {
  TasksRepository(this._remote, this._db, this._outbox, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now {
    _sentSub = _outbox.sent.listen(_onSent);
  }

  final TasksRemoteDataSource _remote;
  final AppDatabase _db;
  final Outbox _outbox;
  final DateTime Function() _now;
  late final StreamSubscription<OutboxSent> _sentSub;
  final _changes = StreamController<String>.broadcast();

  /// Id de la tarea cada vez que cambia (local o al llegar al servidor).
  Stream<String> get changes => _changes.stream;

  static String entityKey(String taskId) => 'task:$taskId';
  static String _detailKey(String id) => 'task:$id';
  static String _agendaKey(DateTime date, bool mine) =>
      'tasks:${TasksRemoteDataSource.isoDate(date)}:${mine ? 'mine' : 'team'}';

  void dispose() {
    _sentSub.cancel();
    _changes.close();
  }

  // ── Lecturas ──────────────────────────────────────────

  Future<DayAgenda> agenda(DateTime date, {bool mine = true}) async {
    final key = _agendaKey(date, mine);
    List<Map<String, dynamic>> items;
    DateTime? cachedAt;
    try {
      items = await _remote.forDate(date, mine: mine);
      await _save(key, items);
    } on DioException {
      final cached = await _read(key);
      if (cached == null) rethrow;
      items = [
        for (final m in (jsonDecode(cached.body) as List).whereType<Map>())
          Map<String, dynamic>.from(m),
      ];
      cachedAt = cached.savedAt;
    }
    // Lo que se hizo sin conexión manda sobre lo que dice el servidor.
    final unsynced = <String>{};
    final tasks = <TaskSummary>[];
    for (final item in items) {
      final id = '${item['id']}';
      final pending = await _outbox.pendingFor(entityKey(id));
      if (pending.isNotEmpty) {
        unsynced.add(id);
        final local = await _read(_detailKey(id));
        if (local != null) {
          tasks.add(TaskSummary.fromJson(_decode(local.body)));
          continue;
        }
      }
      tasks.add(TaskSummary.fromJson(item));
    }
    return DayAgenda(tasks: _sorted(tasks), cachedAt: cachedAt, unsynced: unsynced);
  }

  Future<TaskLoad> detail(String id) async {
    Map<String, dynamic> json;
    DateTime? cachedAt;
    try {
      json = await _remote.detail(id);
    } on DioException {
      final cached = await _read(_detailKey(id));
      if (cached == null) rethrow;
      final pending = await _outbox.pendingFor(entityKey(id));
      return TaskLoad(
        task: TaskDetail.fromJson(_decode(cached.body)),
        cachedAt: cached.savedAt,
        pending: pending.length,
      );
    }
    // Vuelve a aplicar lo que sigue en cola sobre la versión del servidor.
    final pending = await _outbox.pendingFor(entityKey(id));
    for (final action in pending) {
      json = applyLocal(
        json,
        action.method,
        action.path,
        action.body == null ? null : jsonDecode(action.body!),
        _now(),
      );
    }
    await _save(_detailKey(id), json);
    return TaskLoad(task: TaskDetail.fromJson(json), cachedAt: cachedAt, pending: pending.length);
  }

  /// Llaves, códigos y wifi (solo en línea; queda en la bitácora).
  Future<String> accessInfo(String propertyId) => _remote.accessInfo(propertyId);

  // ── Ejecución (funciona sin conexión) ────────────────

  Future<TaskDetail> start(TaskDetail task, {required double lat, required double lng}) =>
      _act(
        task,
        'POST',
        '/tasks/${task.id}/start',
        {'lat': lat, 'lng': lng},
        label: 'Iniciar ${task.summary.property.code}',
      );

  Future<TaskDetail> setItem(TaskDetail task, String itemId, {bool? isDone, String? notes}) =>
      _act(
        task,
        'PATCH',
        '/tasks/${task.id}/checklist/$itemId',
        {'is_done': ?isDone, 'notes': ?notes},
        label: 'Checklist ${task.summary.property.code}',
      );

  Future<TaskDetail> addConsumptions(TaskDetail task, Map<String, double> used) => _act(
    task,
    'POST',
    '/tasks/${task.id}/consumptions',
    {
      'items': [
        for (final e in used.entries)
          if (e.value > 0) {'item_id': e.key, 'quantity': e.value},
      ],
    },
    label: 'Insumos ${task.summary.property.code}',
  );

  Future<TaskDetail> complete(
    TaskDetail task, {
    required double lat,
    required double lng,
    String? notes,
    required List<CustodyReturn> custody,
  }) => _act(
    task,
    'POST',
    '/tasks/${task.id}/complete',
    {
      'lat': lat,
      'lng': lng,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'custody': [for (final c in custody) c.toJson()],
    },
    label: 'Cerrar ${task.summary.property.code}',
    waitUploads: true,
  );

  // ── Supervisor (en línea) ─────────────────────────────

  Future<TaskDetail> decide(TaskDetail task, {required bool approve, String? note}) async {
    await _remote.decide(task.id, approve: approve, note: note);
    final fresh = await detail(task.id);
    _emit(task.id);
    return fresh.task;
  }

  Future<List<TaskAssignee>> assignables() async =>
      [for (final a in await _remote.assignables()) TaskAssignee.fromJson(a)];

  /// Reasignar o reprogramar (en línea).
  Future<void> reschedule(
    String id, {
    String? assigneeId,
    bool changeAssignee = false,
    DateTime? date,
    String? start,
    String? end,
    required String reason,
  }) async {
    await _remote.reschedule(
      id,
      assigneeId: assigneeId,
      changeAssignee: changeAssignee,
      date: date,
      start: start,
      end: end,
      reason: reason,
    );
    _emit(id);
  }

  // ── Interno ──────────────────────────────────────────

  Future<TaskDetail> _act(
    TaskDetail task,
    String method,
    String path,
    Map<String, Object?> body, {
    required String label,
    bool waitUploads = false,
  }) async {
    final json = applyLocal(task.raw, method, path, body, _now());
    await _save(_detailKey(task.id), json);
    await _outbox.enqueue(
      method: method,
      path: path,
      body: body,
      entityKey: entityKey(task.id),
      label: label,
      waitUploads: waitUploads,
    );
    _emit(task.id);
    return TaskDetail.fromJson(json);
  }

  void _onSent(OutboxSent sent) {
    if (!sent.entityKey.startsWith('task:')) return;
    _emit(sent.entityKey.substring(5));
  }

  void _emit(String id) {
    if (!_changes.isClosed) _changes.add(id);
  }

  Future<ApiCacheRow?> _read(String key) =>
      (_db.select(_db.apiCache)..where((t) => t.key.equals(key))).getSingleOrNull();

  Future<void> _save(String key, Object json) => _db
      .into(_db.apiCache)
      .insertOnConflictUpdate(
        ApiCacheCompanion.insert(key: key, body: jsonEncode(json), savedAt: _now()),
      );

  static Map<String, dynamic> _decode(String body) =>
      Map<String, dynamic>.from(jsonDecode(body) as Map);

  /// La que está en progreso arriba; luego por ventana; las terminadas y
  /// canceladas al final.
  static List<TaskSummary> _sorted(Iterable<TaskSummary> tasks) {
    int rank(TaskSummary t) => switch (t.status) {
      TaskStatus.inProgress => 0,
      TaskStatus.returned => 1,
      TaskStatus.pending => 2,
      TaskStatus.done || TaskStatus.validated => 3,
      TaskStatus.cancelled => 4,
    };
    return tasks.toList()..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return (a.windowStart ?? '99').compareTo(b.windowStart ?? '99');
    });
  }
}

/// Aplica una acción de ejecución sobre el JSON de `GET /tasks/{id}`, igual
/// que lo haría el servidor (para verla al instante y sin conexión).
Map<String, dynamic> applyLocal(
  Map<String, dynamic> source,
  String method,
  String path,
  Object? body,
  DateTime now,
) {
  final json = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  final data = body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{};
  final at = now.toUtc().toIso8601String();
  final timeline = [...(json['timeline'] as List? ?? const [])];
  void event(String type, String text, [String? detail]) => timeline.add({
    'at': at,
    'type': type,
    'text': text,
    'actor': 'Tú',
    'detail': ?detail,
  });
  final items = [
    for (final i in (json['items'] as List? ?? const []).whereType<Map>())
      Map<String, dynamic>.from(i),
  ];
  final custody = [
    for (final c in (json['custody'] as List? ?? const []).whereType<Map>())
      Map<String, dynamic>.from(c),
  ];
  double qty(Map<String, dynamic> m) => ((m['quantity'] ?? m['qty']) as num?)?.toDouble() ?? 0;

  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  final action = segments.length >= 3 ? segments[2] : '';

  switch ((method, action)) {
    case ('POST', 'start'):
      json['status'] = 'in_progress';
      json['started_at'] ??= at;
      json['late'] = false;
      event('started', 'Iniciada');
    case ('PATCH', 'checklist') when segments.length >= 4:
      for (final item in items) {
        if ('${item['id']}' != segments[3]) continue;
        if (data['is_done'] is bool) {
          item['is_done'] = data['is_done'];
          item['done_at'] = data['is_done'] == true ? at : null;
        }
        if (data.containsKey('notes')) item['notes'] = data['notes'];
      }
    case ('POST', 'consumptions'):
      final consumption = [
        for (final c in (json['consumption'] as List? ?? const []).whereType<Map>())
          Map<String, dynamic>.from(c),
      ];
      final parts = <String>[];
      for (final line in (data['items'] as List? ?? const []).whereType<Map>()) {
        final id = '${line['item_id']}';
        final used = (line['quantity'] as num?)?.toDouble() ?? 0;
        final held = custody.where((c) => '${c['item_id']}' == id).firstOrNull;
        if (held == null) continue;
        held['quantity'] = (qty(held) - used).clamp(0, double.infinity);
        final existing = consumption.where((c) => '${c['item_id']}' == id).firstOrNull;
        if (existing != null) {
          existing['qty'] = ((existing['qty'] as num?)?.toDouble() ?? 0) + used;
        } else {
          consumption.add({
            'item_id': id,
            'item': held['name'],
            'qty': used,
            'unit': held['unit'],
          });
        }
        parts.add('${held['name']} ${_num(used)}');
      }
      custody.removeWhere((c) => qty(c) <= 0.0005);
      json['consumption'] = consumption;
      event('consumption', 'Registró insumos', parts.join(', '));
    case ('POST', 'complete'):
      json['status'] = 'done';
      json['finished_at'] = at;
      json['late'] = false;
      if (data['notes'] != null) json['completion_notes'] = data['notes'];
      final missing = <String>[];
      for (final line in (data['custody'] as List? ?? const []).whereType<Map>()) {
        final id = '${line['item_id']}';
        final held = custody.where((c) => '${c['item_id']}' == id).firstOrNull;
        if (held == null) continue;
        double n(String k) => (line[k] as num?)?.toDouble() ?? 0;
        final gap = qty(held) - n('returned') - n('consumed') - n('kept');
        if (gap > 0.0005) missing.add('${held['name']} ${_num(gap)}');
        held['quantity'] = n('kept');
      }
      custody.removeWhere((c) => qty(c) <= 0.0005);
      if (missing.isNotEmpty) json['discrepancy'] = 'Faltan: ${missing.join(', ')}';
      event('finished', 'Terminada');
  }

  json['items'] = items;
  json['custody'] = custody;
  json['timeline'] = timeline;
  // Avance por sección, como lo arma el servidor.
  if (items.isNotEmpty) {
    final sections = <String, List<int>>{};
    for (final i in items) {
      final s = sections.putIfAbsent('${i['section']}', () => [0, 0]);
      s[0]++;
      if (i['is_done'] == true) s[1]++;
    }
    json['checklist'] = [
      for (final e in sections.entries) {'name': e.key, 'total': e.value[0], 'done': e.value[1]},
    ];
  }
  return json;
}

String _num(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);

@Riverpod(keepAlive: true)
TasksRepository tasksRepository(Ref ref) {
  final repo = TasksRepository(
    ref.watch(tasksRemoteDataSourceProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(outboxProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
}
