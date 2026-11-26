import 'dart:io';

import 'package:argos_app/features/camera/presentation/pages/camera_page.dart';
import 'package:argos_app/features/uploads/data/datasources/files_remote_datasource.dart';
import 'package:argos_app/features/uploads/data/repositories/upload_queue.dart';
import 'package:argos_app/features/uploads/models/pending_upload.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fotos de un formulario que aún no existe en el servidor (reporte o
/// solución de una incidencia). Se suben en cuanto se toman; el formulario
/// se envía con los `file_id` cuando todas terminaron.
class DraftPhotos {
  DraftPhotos(String draftId) : entityType = '${draftEntityPrefix}ticket', entityId = draftId;

  final String entityType;
  final String entityId;

  List<PendingUpload> of(WidgetRef ref) =>
      ref.watch(entityUploadsProvider(entityType, entityId)).valueOrNull ?? const [];

  static bool allUploaded(List<PendingUpload> list) =>
      list.every((u) => u.status == UploadStatus.done && u.fileId != null);

  static List<String> fileIds(List<PendingUpload> list) => [
    for (final u in list)
      if (u.fileId != null) u.fileId!,
  ];

  Future<void> take(
    BuildContext context,
    WidgetRef ref, {
    required String module,
    required String kind,
    String? title,
    String? propertyCode,
  }) async {
    final shots = await openCamera(
      context,
      CameraRequest(title: title, propertyCode: propertyCode, maxPhotos: 6),
    );
    if (shots == null) return;
    final queue = ref.read(uploadQueueProvider);
    for (final bytes in shots) {
      await queue.enqueue(bytes: bytes, module: module, kind: kind, entityType: entityType, entityId: entityId);
    }
  }

  /// Al salir sin enviar: borra las fotos del teléfono y de la cola.
  Future<void> discard(UploadQueue queue) async {
    final list = await queue.watchEntity(entityType, entityId).first;
    for (final u in list) {
      await queue.remove(u.id);
    }
  }
}

/// Rejilla de un [DraftPhotos] con su estado de subida.
class DraftPhotoGrid extends ConsumerWidget {
  const DraftPhotoGrid({super.key, required this.photos, required this.onAdd, this.addLabel = 'Tomar foto'});

  final List<PendingUpload> photos;
  final VoidCallback? onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PhotoGrid(
      addLabel: addLabel,
      onAdd: onAdd,
      onOpen: (i) async {
        final p = photos[i];
        final remove = await showConfirmSheet(
          context,
          title: 'Quitar esta foto',
          message: 'La foto se borra del teléfono y no se enviará.',
          confirmLabel: 'Quitar',
          destructive: true,
        );
        if (remove) await ref.read(uploadQueueProvider).remove(p.id);
      },
      photos: [
        for (final p in photos)
          PhotoItem(
            image: FileImage(File(p.localPath)),
            status: switch (p.status) {
              UploadStatus.queued => PhotoUploadStatus.queued,
              UploadStatus.uploading => PhotoUploadStatus.uploading,
              UploadStatus.done => PhotoUploadStatus.done,
              UploadStatus.error => PhotoUploadStatus.error,
            },
            progress: p.progress,
            onRetry: () => ref.read(uploadQueueProvider).retry(p.id),
          ),
      ],
    );
  }
}
