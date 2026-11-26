import 'dart:async';
import 'dart:convert';

import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

/// Envía una acción guardada. Lanza [DioException] sin respuesta si no hay
/// red (se reintenta) o [ApiException] si el servidor la rechazó.
typedef OutboxSender =
    Future<Map<String, dynamic>> Function(String method, String path, Object? body);

/// Resumen de la cola para la pantalla de sincronización.
class OutboxSummary {
  const OutboxSummary({this.queued = 0, this.failed = 0});

  final int queued;
  final int failed;

  bool get isEmpty => queued == 0 && failed == 0;
}

/// Una acción ya aceptada por el servidor.
class OutboxSent {
  const OutboxSent(this.entityKey, this.method, this.path, this.response);

  final String entityKey;
  final String method;
  final String path;
  final Map<String, dynamic> response;
}

/// Cola de cambios hechos sin conexión (fase02 §5). Se envían en orden: si
/// uno falla por red se detiene y sigue cuando vuelve; si el servidor lo
/// rechaza queda en error con su motivo y se sigue con el siguiente.
class Outbox {
  Outbox({required AppDatabase db, required OutboxSender send, DateTime Function()? clock})
    : _db = db,
      _send = send,
      _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final OutboxSender _send;
  final DateTime Function() _now;
  Future<void>? _running;

  /// Si devuelve false no se envía nada (sin sesión o sin conexión).
  bool Function() canSend = () => true;

  /// Si devuelve true, las acciones que esperan fotos no se envían aún.
  Future<bool> Function() uploadsPending = () async => false;

  final _sent = StreamController<OutboxSent>.broadcast();

  /// Cada acción enviada con la respuesta del servidor (para refrescar
  /// pantallas y cachés).
  Stream<OutboxSent> get sent => _sent.stream;

  void dispose() => _sent.close();

  /// Guarda la acción y la intenta enviar enseguida.
  Future<void> enqueue({
    required String method,
    required String path,
    Object? body,
    required String entityKey,
    required String label,
    bool waitUploads = false,
  }) async {
    await _db
        .into(_db.pendingActions)
        .insert(
          PendingActionsCompanion.insert(
            method: method,
            path: path,
            body: Value(body == null ? null : jsonEncode(body)),
            entityKey: entityKey,
            label: label,
            waitUploads: Value(waitUploads),
            createdAt: _now(),
          ),
        );
    unawaited(process());
  }

  /// Acciones de una entidad aún sin enviar.
  Stream<List<PendingActionRow>> watchEntity(String entityKey) =>
      (_db.select(_db.pendingActions)
            ..where((a) => a.entityKey.equals(entityKey))
            ..orderBy([(a) => OrderingTerm.asc(a.id)]))
          .watch();

  Future<List<PendingActionRow>> pendingFor(String entityKey) =>
      (_db.select(_db.pendingActions)
            ..where((a) => a.entityKey.equals(entityKey) & a.status.equals('queued')))
          .get();

  Stream<OutboxSummary> watchSummary() => _db.select(_db.pendingActions).watch().map(
    (rows) => OutboxSummary(
      queued: rows.where((r) => r.status == 'queued').length,
      failed: rows.where((r) => r.status == 'error').length,
    ),
  );

  Stream<List<PendingActionRow>> watchAll() =>
      (_db.select(_db.pendingActions)..orderBy([(a) => OrderingTerm.asc(a.id)])).watch();

  Future<void> discard(int id) =>
      (_db.delete(_db.pendingActions)..where((a) => a.id.equals(id))).go();

  Future<void> retry(int id) async {
    await (_db.update(_db.pendingActions)..where((a) => a.id.equals(id))).write(
      const PendingActionsCompanion(status: Value('queued'), lastError: Value(null)),
    );
    unawaited(process());
  }

  /// Envía lo pendiente (una sola pasada a la vez).
  Future<void> process() => _running ??= _processAll().whenComplete(() => _running = null);

  Future<void> _processAll() async {
    while (canSend()) {
      final next =
          await (_db.select(_db.pendingActions)
                ..where((a) => a.status.equals('queued'))
                ..orderBy([(a) => OrderingTerm.asc(a.id)])
                ..limit(1))
              .getSingleOrNull();
      if (next == null) return;
      if (next.waitUploads && await uploadsPending()) return;
      try {
        final response = await _send(
          next.method,
          next.path,
          next.body == null ? null : jsonDecode(next.body!),
        );
        await discard(next.id);
        if (!_sent.isClosed) {
          _sent.add(OutboxSent(next.entityKey, next.method, next.path, response));
        }
      } on ApiException catch (e) {
        if (e.statusCode == 401 || e.statusCode >= 500) {
          await _bump(next, e.detail);
          return;
        }
        await (_db.update(_db.pendingActions)..where((a) => a.id.equals(next.id))).write(
          PendingActionsCompanion(
            status: const Value('error'),
            attempts: Value(next.attempts + 1),
            lastError: Value(e.detail),
          ),
        );
        if (!_sent.isClosed) {
          _sent.add(OutboxSent(next.entityKey, next.method, next.path, const {}));
        }
      } on DioException catch (e) {
        await _bump(next, e.message ?? 'Sin conexión');
        return;
      }
    }
  }

  Future<void> _bump(PendingActionRow row, String error) =>
      (_db.update(_db.pendingActions)..where((a) => a.id.equals(row.id))).write(
        PendingActionsCompanion(attempts: Value(row.attempts + 1), lastError: Value(error)),
      );
}
