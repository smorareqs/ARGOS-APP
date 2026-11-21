import 'package:argos_app/core/database/tables/session_cache_table.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SessionCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // La v1 guardaba usuarios con contraseña MD5 para un login local que
        // se eliminó: la app autentica siempre contra el backend.
        await m.deleteTable('usuarios');
        await m.createTable(sessionCache);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'argos_db');
  }
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
