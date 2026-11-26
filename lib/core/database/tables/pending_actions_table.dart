import 'package:drift/drift.dart';

/// Cola local de cambios hechos sin conexión (fase02 §5): marcar puntos del
/// checklist, iniciar, registrar insumos y el cierre "listo para cerrar".
/// Se envían en orden al volver la red.
@DataClassName('PendingActionRow')
class PendingActions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Método y ruta de la API, p. ej. `PATCH /tasks/…/checklist/…`.
  TextColumn get method => text()();
  TextColumn get path => text()();

  /// Cuerpo JSON (null = sin cuerpo).
  TextColumn get body => text().nullable()();

  /// Entidad afectada (`task:<id>`) para mostrar "pendiente de enviar".
  TextColumn get entityKey => text()();

  /// Texto corto para la pantalla de sincronización.
  TextColumn get label => text()();

  /// Espera a que no queden fotos por subir (el cierre las necesita).
  BoolColumn get waitUploads => boolean().withDefault(const Constant(false))();

  /// queued o error (el servidor lo rechazó; ver lastError).
  TextColumn get status => text().withDefault(const Constant('queued'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
