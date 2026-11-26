import 'dart:async';

import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/connectivity_service.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:argos_app/core/outbox/outbox.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'outbox_providers.g.dart';

@Riverpod(keepAlive: true)
Outbox outbox(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  final db = ref.watch(appDatabaseProvider);
  final outbox = Outbox(
    db: db,
    send: (method, path, body) async {
      try {
        final response = await dio.request<dynamic>(
          path,
          data: body,
          options: Options(method: method),
        );
        final data = response.data;
        return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      } on DioException catch (e) {
        final api = ApiException.fromDio(e);
        if (api != null) throw api;
        rethrow;
      }
    },
  );
  // Las fotos van primero: el cierre de una tarea las necesita en el servidor.
  outbox.uploadsPending = () async {
    final count = db.pendingUploads.id.count();
    final row = await (db.selectOnly(db.pendingUploads)
          ..addColumns([count])
          ..where(db.pendingUploads.status.isNotIn(['done', 'error'])))
        .getSingle();
    return (row.read(count) ?? 0) > 0;
  };
  ref.onDispose(outbox.dispose);
  return outbox;
}

/// Mantiene la cola de cambios en marcha mientras la app está abierta:
/// envía al entrar, al volver la conexión, al regresar a la app y cuando
/// terminan de subir las fotos (el cierre las espera).
@Riverpod(keepAlive: true)
void outboxRunner(Ref ref) {
  final outbox = ref.watch(outboxProvider);

  bool online() {
    final auth = ref.read(sessionControllerProvider);
    return auth is AuthSignedIn && !auth.offline;
  }

  void kick() {
    if (online()) unawaited(outbox.process());
  }

  outbox.canSend = online;
  kick();
  ref.listen(sessionControllerProvider, (_, _) => kick());
  final network = ref.watch(connectivityServiceProvider).watch().listen((up) {
    if (up) kick();
  });
  final uploads = ref.watch(uploadQueueProvider).watchSummary().listen((s) {
    if (s.pending == 0) kick();
  });
  final lifecycle = AppLifecycleListener(onResume: kick);
  ref.onDispose(() {
    network.cancel();
    uploads.cancel();
    lifecycle.dispose();
  });
}

/// Conteo global de la cola de cambios.
@riverpod
Stream<OutboxSummary> outboxSummary(Ref ref) => ref.watch(outboxProvider).watchSummary();

/// Cambios sin enviar de una entidad (`task:<id>`).
@riverpod
Stream<List<PendingActionRow>> entityActions(Ref ref, String entityKey) =>
    ref.watch(outboxProvider).watchEntity(entityKey);
