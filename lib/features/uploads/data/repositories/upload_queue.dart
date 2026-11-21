import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/features/uploads/data/datasources/files_remote_datasource.dart';
import 'package:argos_app/features/uploads/models/pending_upload.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Cola local de subidas (fase02 §5). Guarda cada foto en el teléfono y en
/// `pending_uploads`, y la sube con presign → subida → confirm. Si algo
/// falla reintenta con espera creciente (15 s, 30 s, 1 min… hasta 30 min);
/// sin conexión se detiene y sigue cuando vuelve la red.
class UploadQueue {
  UploadQueue({
    required AppDatabase db,
    required FilesRemoteDataSource remote,
    required Future<Directory> Function() storageDir,
    DateTime Function()? clock,
  }) : _db = db,
       _remote = remote,
       _storageDir = storageDir,
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final FilesRemoteDataSource _remote;
  final Future<Directory> Function() _storageDir;
  final DateTime Function() _now;

  /// Progreso en memoria de las subidas en curso (no vale la pena guardarlo).
  final _progress = <String, double>{};
  final _progressChanges = StreamController<void>.broadcast();

  Future<void>? _running;
  Timer? _retryTimer;
  var _disposed = false;

  /// Si devuelve false no se sube nada (sin sesión o sin conexión).
  bool Function() canUpload = () => true;

  static const _maxBackoff = Duration(minutes: 30);

  /// Espera antes del reintento número [attempts].
  static Duration backoffFor(int attempts) {
    final seconds = 15 * math.pow(2, math.max(0, attempts - 1));
    return Duration(
      seconds: math.min(seconds.toInt(), _maxBackoff.inSeconds),
    );
  }

  /// Guarda una foto ya procesada y la pone en cola. Devuelve su id.
  Future<String> enqueue({
    required Uint8List bytes,
    required String module,
    required String kind,
    required String entityType,
    required String entityId,
    String contentType = 'image/jpeg',
  }) async {
    final id = const Uuid().v4();
    final dir = Directory(p.join((await _storageDir()).path, 'uploads'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, '$id.jpg'));
    await file.writeAsBytes(bytes, flush: true);

    await _db
        .into(_db.pendingUploads)
        .insert(
          PendingUploadsCompanion.insert(
            id: id,
            localPath: file.path,
            module: module,
            kind: kind,
            entityType: entityType,
            entityId: entityId,
            contentType: contentType,
            sizeBytes: bytes.length,
            status: UploadStatus.queued.name,
            createdAt: _now(),
          ),
        );
    unawaited(process());
    return id;
  }

  /// Archivos de una entidad (p. ej. un ítem del checklist), del más viejo
  /// al más nuevo, con el progreso de los que están subiendo.
  Stream<List<PendingUpload>> watchEntity(String entityType, String entityId) {
    final query = _db.select(_db.pendingUploads)
      ..where(
        (t) => t.entityType.equals(entityType) & t.entityId.equals(entityId),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return _withProgress(query.watch());
  }

  /// Conteo global: en cola o subiendo, y con error.
  Stream<UploadSummary> watchSummary() {
    final query = _db.select(_db.pendingUploads)
      ..where((t) => t.status.isNotValue(UploadStatus.done.name));
    return query.watch().map((rows) {
      final failed = rows
          .where((r) => r.status == UploadStatus.error.name)
          .length;
      return UploadSummary(pending: rows.length - failed, failed: failed);
    });
  }

  /// Reintenta ya, sin esperar la espera creciente.
  Future<void> retry(String id) async {
    await (_db.update(_db.pendingUploads)..where((t) => t.id.equals(id))).write(
      PendingUploadsCompanion(
        status: Value(UploadStatus.queued.name),
        nextAttemptAt: const Value(null),
      ),
    );
    unawaited(process());
  }

  /// Quita un archivo de la cola y lo borra del teléfono.
  Future<void> remove(String id) async {
    final row = await (_db.select(
      _db.pendingUploads,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await (_db.delete(_db.pendingUploads)..where((t) => t.id.equals(id))).go();
    _deleteQuietly(row.localPath);
  }

  /// Al arrancar: lo que quedó "subiendo" (la app se cerró a medias) vuelve
  /// a la cola, y se borran las subidas terminadas hace más de 7 días.
  Future<void> recover() async {
    await (_db.update(_db.pendingUploads)
          ..where((t) => t.status.equals(UploadStatus.uploading.name)))
        .write(PendingUploadsCompanion(status: Value(UploadStatus.queued.name)));
    final old = await (_db.select(_db.pendingUploads)..where(
          (t) =>
              t.status.equals(UploadStatus.done.name) &
              t.uploadedAt.isSmallerThanValue(
                _now().subtract(const Duration(days: 7)),
              ),
        ))
        .get();
    for (final row in old) {
      await remove(row.id);
    }
  }

  /// Sube todo lo que esté listo para intentarse. Si ya hay una pasada en
  /// curso devuelve esa misma.
  Future<void> process() => _running ??= _processAll().whenComplete(() {
    _running = null;
  });

  Future<void> _processAll() async {
    while (!_disposed && canUpload()) {
      final now = _now();
      final next =
          await (_db.select(_db.pendingUploads)
                ..where(
                  (t) =>
                      t.status.isIn([
                        UploadStatus.queued.name,
                        UploadStatus.error.name,
                      ]) &
                      (t.nextAttemptAt.isNull() |
                          t.nextAttemptAt.isSmallerOrEqualValue(now)),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
                ..limit(1))
              .getSingleOrNull();
      if (next == null) break;
      final keepGoing = await _uploadOne(next);
      if (!keepGoing) break;
    }
    await _scheduleRetry();
  }

  /// Devuelve false si conviene detener la pasada (sin conexión).
  Future<bool> _uploadOne(PendingUploadRow row) async {
    await _write(row.id, status: UploadStatus.uploading);
    _setProgress(row.id, 0);
    try {
      var fileId = row.fileId;
      if (fileId == null) {
        final file = File(row.localPath);
        if (!await file.exists()) {
          await _fail(row, 'La foto ya no está en el teléfono.');
          return true;
        }
        // Cada intento pide una URL nueva: las prefirmadas vencen en 15 min.
        final target = await _remote.presign(
          module: row.module,
          kind: row.kind,
          entityType: row.entityType,
          entityId: row.entityId,
          contentType: row.contentType,
          size: row.sizeBytes,
        );
        await _remote.upload(
          target,
          file,
          contentType: row.contentType,
          onProgress: (v) => _setProgress(row.id, v),
        );
        fileId = target.fileId;
        // Ya está subida: si el confirm falla solo se reintenta el confirm.
        await _write(row.id, fileId: fileId);
      }
      await _remote.confirm(fileId);
      await _write(row.id, status: UploadStatus.done, uploadedAt: _now());
      return true;
    } on ApiException catch (e) {
      await _fail(row, e.detail);
      return true;
    } on DioException catch (_) {
      await _fail(row, 'Sin conexión. Se reintentará solo.');
      return false;
    } catch (e) {
      await _fail(row, 'No se pudo subir: $e');
      return true;
    } finally {
      _setProgress(row.id, null);
    }
  }

  Future<void> _fail(PendingUploadRow row, String message) async {
    final attempts = row.attempts + 1;
    await (_db.update(
      _db.pendingUploads,
    )..where((t) => t.id.equals(row.id))).write(
      PendingUploadsCompanion(
        status: Value(UploadStatus.error.name),
        attempts: Value(attempts),
        lastError: Value(message),
        nextAttemptAt: Value(_now().add(backoffFor(attempts))),
      ),
    );
  }

  Future<void> _write(
    String id, {
    UploadStatus? status,
    String? fileId,
    DateTime? uploadedAt,
  }) {
    return (_db.update(
      _db.pendingUploads,
    )..where((t) => t.id.equals(id))).write(
      PendingUploadsCompanion(
        status: status == null ? const Value.absent() : Value(status.name),
        fileId: fileId == null ? const Value.absent() : Value(fileId),
        uploadedAt: uploadedAt == null
            ? const Value.absent()
            : Value(uploadedAt),
        lastError: status == UploadStatus.done
            ? const Value(null)
            : const Value.absent(),
      ),
    );
  }

  /// Programa la siguiente pasada para el reintento más próximo.
  Future<void> _scheduleRetry() async {
    _retryTimer?.cancel();
    if (_disposed) return;
    final soonest =
        await (_db.select(_db.pendingUploads)
              ..where(
                (t) =>
                    t.status.equals(UploadStatus.error.name) &
                    t.nextAttemptAt.isNotNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.nextAttemptAt)])
              ..limit(1))
            .getSingleOrNull();
    final at = soonest?.nextAttemptAt;
    if (at == null) return;
    final wait = at.difference(_now());
    _retryTimer = Timer(
      wait.isNegative ? Duration.zero : wait + const Duration(seconds: 1),
      () => unawaited(process()),
    );
  }

  void _setProgress(String id, double? value) {
    if (value == null) {
      _progress.remove(id);
    } else {
      _progress[id] = value;
    }
    if (!_progressChanges.isClosed) _progressChanges.add(null);
  }

  Stream<List<PendingUpload>> _withProgress(
    Stream<List<PendingUploadRow>> rows,
  ) {
    late StreamController<List<PendingUpload>> controller;
    StreamSubscription<List<PendingUploadRow>>? rowsSub;
    StreamSubscription<void>? progressSub;
    var latest = const <PendingUploadRow>[];

    void emit() {
      if (controller.isClosed) return;
      controller.add([
        for (final r in latest) _toModel(r).withProgress(_progress[r.id]),
      ]);
    }

    controller = StreamController<List<PendingUpload>>(
      onListen: () {
        rowsSub = rows.listen((r) {
          latest = r;
          emit();
        }, onError: controller.addError);
        progressSub = _progressChanges.stream.listen((_) => emit());
      },
      onCancel: () async {
        await rowsSub?.cancel();
        await progressSub?.cancel();
      },
    );
    return controller.stream;
  }

  static PendingUpload _toModel(PendingUploadRow r) => PendingUpload(
    id: r.id,
    localPath: r.localPath,
    entityType: r.entityType,
    entityId: r.entityId,
    kind: r.kind,
    status: UploadStatus.parse(r.status),
    attempts: r.attempts,
    createdAt: r.createdAt,
    fileId: r.fileId,
    lastError: r.lastError,
  );

  static void _deleteQuietly(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _progressChanges.close();
  }
}
