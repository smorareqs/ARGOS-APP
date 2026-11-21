import 'package:drift/drift.dart';

/// Cola local de archivos por subir (fase02 §5 "Sin conexión"). Cada fila es
/// una foto ya comprimida y guardada en el teléfono; se sube con el flujo
/// presign → subida → confirm de fase01 §3.8 y se reintenta con espera
/// creciente hasta lograrlo.
@DataClassName('PendingUploadRow')
class PendingUploads extends Table {
  /// UUID generado en el teléfono.
  TextColumn get id => text()();

  /// Ruta del archivo local ya procesado.
  TextColumn get localPath => text()();

  /// Módulo, tipo y entidad dueños del archivo (`files` en el backend).
  TextColumn get module => text()();
  TextColumn get kind => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get contentType => text()();
  IntColumn get sizeBytes => integer()();

  /// queued, uploading, done o error (ver `UploadStatus`).
  TextColumn get status => text()();

  /// Id del registro `files` una vez pedido el presign.
  TextColumn get fileId => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Antes de esta hora no se reintenta (espera creciente).
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get uploadedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
