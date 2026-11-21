import 'dart:convert';

import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/features/tasks/data/datasources/tasks_remote_datasource.dart';
import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasks_repository.g.dart';

/// Agenda de un día, con de dónde salió.
class DayAgenda {
  const DayAgenda({required this.tasks, this.cachedAt});

  final List<TaskSummary> tasks;

  /// Si no es null, no hubo conexión y es la copia guardada a esa hora.
  final DateTime? cachedAt;

  bool get fromCache => cachedAt != null;
}

/// Lee la agenda del backend y guarda la última copia de cada día para
/// mostrarla sin conexión (ux-ui.md B1, fase02 §5).
class TasksRepository {
  TasksRepository(this._remote, this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final TasksRemoteDataSource _remote;
  final AppDatabase _db;
  final DateTime Function() _now;

  Future<DayAgenda> agenda(DateTime date) async {
    final key = 'tasks:${TasksRemoteDataSource.isoDate(date)}';
    try {
      final items = await _remote.forDate(date);
      await _db
          .into(_db.apiCache)
          .insertOnConflictUpdate(
            ApiCacheCompanion.insert(
              key: key,
              body: jsonEncode(items),
              savedAt: _now(),
            ),
          );
      return DayAgenda(tasks: _sorted(items.map(TaskSummary.fromJson)));
    } on DioException {
      // Sin respuesta del servidor: la copia guardada, si hay.
      final cached = await (_db.select(
        _db.apiCache,
      )..where((t) => t.key.equals(key))).getSingleOrNull();
      if (cached == null) rethrow;
      final items = (jsonDecode(cached.body) as List).whereType<Map>().map(
        (m) => TaskSummary.fromJson(Map<String, dynamic>.from(m)),
      );
      return DayAgenda(tasks: _sorted(items), cachedAt: cached.savedAt);
    }
  }

  /// La que está en progreso arriba; luego por ventana; las terminadas y
  /// canceladas al final.
  static List<TaskSummary> _sorted(Iterable<TaskSummary> tasks) {
    int rank(TaskSummary t) => switch (t.status) {
      TaskStatus.inProgress => 0,
      TaskStatus.pending => 1,
      TaskStatus.completed || TaskStatus.validated => 2,
      TaskStatus.cancelled => 3,
    };
    return tasks.toList()..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return (a.windowStart ?? '99').compareTo(b.windowStart ?? '99');
    });
  }
}

@Riverpod(keepAlive: true)
TasksRepository tasksRepository(Ref ref) => TasksRepository(
  ref.watch(tasksRemoteDataSourceProvider),
  ref.watch(appDatabaseProvider),
);
