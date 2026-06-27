import 'package:argos_app/core/database/tables/usuarios_table.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Usuarios])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  Future<Usuario?> findUsuarioByCode(String codigo) {
    return (select(usuarios)..where((u) => u.codigo.equals(codigo)))
        .getSingleOrNull();
  }

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
