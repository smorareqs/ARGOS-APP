import 'package:drift/drift.dart';

/// Última respuesta conocida de lecturas que deben verse sin conexión
/// (p. ej. la agenda del día), guardada tal cual como JSON.
@DataClassName('ApiCacheRow')
class ApiCache extends Table {
  /// Clave de la lectura, p. ej. `tasks:2026-10-22`.
  TextColumn get key => text()();
  TextColumn get body => text()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
