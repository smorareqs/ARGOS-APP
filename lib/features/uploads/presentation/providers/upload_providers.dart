import 'dart:async';
import 'dart:io';

import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/core/network/connectivity_service.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/uploads/data/datasources/files_remote_datasource.dart';
import 'package:argos_app/features/uploads/data/repositories/upload_queue.dart';
import 'package:argos_app/features/uploads/models/pending_upload.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upload_providers.g.dart';

/// Carpeta donde se guardan las fotos mientras esperan subir.
@Riverpod(keepAlive: true)
Future<Directory> Function() uploadStorageDir(Ref ref) =>
    getApplicationDocumentsDirectory;

@Riverpod(keepAlive: true)
UploadQueue uploadQueue(Ref ref) {
  final queue = UploadQueue(
    db: ref.watch(appDatabaseProvider),
    remote: ref.watch(filesRemoteDataSourceProvider),
    storageDir: ref.watch(uploadStorageDirProvider),
  );
  ref.onDispose(queue.dispose);
  return queue;
}

/// Mantiene la cola en marcha mientras la app está abierta: sube al entrar,
/// al volver la conexión y al regresar a la app. Solo con sesión en línea,
/// porque la subida necesita el token.
@Riverpod(keepAlive: true)
void uploadQueueRunner(Ref ref) {
  final queue = ref.watch(uploadQueueProvider);

  bool online() {
    final auth = ref.read(sessionControllerProvider);
    return auth is AuthSignedIn && !auth.offline;
  }

  void kick() {
    if (online()) unawaited(queue.process());
  }

  queue.canUpload = online;
  unawaited(queue.recover().then((_) => kick()));

  ref.listen(sessionControllerProvider, (_, _) => kick());
  final network = ref.watch(connectivityServiceProvider).watch().listen((up) {
    if (up) kick();
  });
  final lifecycle = AppLifecycleListener(onResume: kick);
  ref.onDispose(() {
    network.cancel();
    lifecycle.dispose();
  });
}

/// Fotos en cola de una entidad, con su estado y progreso.
@riverpod
Stream<List<PendingUpload>> entityUploads(
  Ref ref,
  String entityType,
  String entityId,
) => ref.watch(uploadQueueProvider).watchEntity(entityType, entityId);

/// Conteo global de la cola.
@riverpod
Stream<UploadSummary> uploadSummary(Ref ref) =>
    ref.watch(uploadQueueProvider).watchSummary();
