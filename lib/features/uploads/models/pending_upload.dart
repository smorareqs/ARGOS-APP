/// Estado de un archivo en la cola de subida.
enum UploadStatus {
  /// Esperando turno (o conexión).
  queued,

  /// Subiendo ahora.
  uploading,

  /// Subido y confirmado por el backend.
  done,

  /// Falló; se reintenta solo con espera creciente o al tocar "Reintentar".
  error;

  static UploadStatus parse(String value) => UploadStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => UploadStatus.queued,
  );
}

/// Un archivo de la cola de subida, tal como lo ve la UI.
class PendingUpload {
  const PendingUpload({
    required this.id,
    required this.localPath,
    required this.entityType,
    required this.entityId,
    required this.kind,
    required this.status,
    required this.attempts,
    required this.createdAt,
    this.fileId,
    this.lastError,
    this.progress,
  });

  final String id;

  /// Foto ya comprimida en el teléfono (sirve también de miniatura).
  final String localPath;
  final String entityType;
  final String entityId;
  final String kind;
  final UploadStatus status;
  final int attempts;
  final DateTime createdAt;

  /// Id en `files` del backend cuando ya se subió.
  final String? fileId;
  final String? lastError;

  /// 0 a 1 mientras sube, si se conoce.
  final double? progress;

  PendingUpload withProgress(double? value) => PendingUpload(
    id: id,
    localPath: localPath,
    entityType: entityType,
    entityId: entityId,
    kind: kind,
    status: status,
    attempts: attempts,
    createdAt: createdAt,
    fileId: fileId,
    lastError: lastError,
    progress: value,
  );
}

/// Conteo global de la cola (para la barra sin conexión y la pantalla Sync).
class UploadSummary {
  const UploadSummary({this.pending = 0, this.failed = 0});

  /// En cola o subiendo.
  final int pending;
  final int failed;

  bool get isEmpty => pending == 0 && failed == 0;
}
