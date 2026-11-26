import 'dart:io';

import 'package:argos_app/core/network/dio_client.dart';
import 'package:argos_app/features/camera/presentation/pages/camera_page.dart';
import 'package:argos_app/features/tasks/models/task_detail.dart';
import 'package:argos_app/features/uploads/models/pending_upload.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_photos.g.dart';

/// Entidad con la que se suben las fotos del checklist (reglas `tasks/*`).
const checklistEntity = 'task_checklist_item';

/// URL de descarga de un archivo ya subido (vence en 5 min; se guarda 4).
@riverpod
Future<String> fileUrl(Ref ref, String fileId) async {
  final link = ref.keepAlive();
  Future<void>.delayed(const Duration(minutes: 4), link.close);
  final res = await ref.watch(dioClientProvider).get<dynamic>('/files/$fileId/url');
  return '${(res.data as Map)['url']}';
}

/// Una foto de un punto: la del teléfono (si se tomó aquí) o la del servidor.
class ItemPhoto {
  const ItemPhoto({required this.kind, this.local, this.fileId});

  final PhotoKind kind;
  final PendingUpload? local;
  final String? fileId;

  bool get uploaded => fileId != null || local?.status == UploadStatus.done;
  bool get failed => local?.status == UploadStatus.error;
}

/// Junta las fotos del servidor con las de la cola de subida del teléfono.
List<ItemPhoto> mergePhotos(ChecklistItem item, List<PendingUpload> uploads) {
  final out = <ItemPhoto>[];
  final seen = <String>{};
  for (final u in uploads) {
    out.add(ItemPhoto(kind: PhotoKind.parse(u.kind), local: u, fileId: u.fileId));
    if (u.fileId != null) seen.add(u.fileId!);
  }
  for (final p in item.photos) {
    if (seen.contains(p.fileId)) continue;
    out.add(ItemPhoto(kind: p.kind, fileId: p.fileId));
  }
  return out;
}

/// Fotos que le faltan a un punto para poder cerrar (0 si está completo).
int missingPhotos(ChecklistItem item, List<ItemPhoto> photos) {
  final usable = photos.where((p) => !p.failed);
  if (item.requiresBeforeAfter) {
    return (usable.any((p) => p.kind == PhotoKind.before) ? 0 : 1) +
        (usable.any((p) => p.kind == PhotoKind.after) ? 0 : 1);
  }
  if (item.requiresPhoto) return usable.isEmpty ? 1 : 0;
  return 0;
}

/// Qué foto toca tomar: en antes/después, primero el "antes".
PhotoKind nextKind(ChecklistItem item, List<ItemPhoto> photos) {
  if (!item.requiresBeforeAfter) return PhotoKind.evidence;
  return photos.any((p) => p.kind == PhotoKind.before) ? PhotoKind.after : PhotoKind.before;
}

PhotoUploadStatus photoStatus(ItemPhoto p) => switch (p.local?.status) {
  null => PhotoUploadStatus.done,
  UploadStatus.queued => PhotoUploadStatus.queued,
  UploadStatus.uploading => PhotoUploadStatus.uploading,
  UploadStatus.done => PhotoUploadStatus.done,
  UploadStatus.error => PhotoUploadStatus.error,
};

/// PNG transparente de 1×1 mientras carga la foto del servidor.
final _transparent = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, //
    0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F,
    0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00,
    0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

/// Imagen de una foto: el archivo local si existe, si no la URL del servidor.
ImageProvider photoImage(WidgetRef ref, ItemPhoto p) {
  final local = p.local;
  if (local != null && File(local.localPath).existsSync()) {
    return FileImage(File(local.localPath));
  }
  if (p.fileId == null) return _transparent;
  final url = ref.watch(fileUrlProvider(p.fileId!)).valueOrNull;
  return url == null ? _transparent : NetworkImage(url);
}

/// Abre la cámara para un punto y pone las fotos en la cola de subida.
/// Devuelve cuántas se tomaron.
Future<int> takeItemPhotos(
  BuildContext context,
  WidgetRef ref, {
  required ChecklistItem item,
  required List<ItemPhoto> photos,
  required String propertyCode,
}) async {
  final kind = nextKind(item, photos);
  final before = photos.where((p) => p.kind == PhotoKind.before).firstOrNull;
  final shots = await openCamera(
    context,
    CameraRequest(
      title: kind == PhotoKind.evidence ? item.text : '${item.text} · ${kind.label}',
      propertyCode: propertyCode,
      reference: kind == PhotoKind.after && before != null ? photoImage(ref, before) : null,
      referenceLabel: 'Antes',
      maxPhotos: kind == PhotoKind.evidence ? 6 : 1,
    ),
  );
  if (shots == null || shots.isEmpty) return 0;
  final queue = ref.read(uploadQueueProvider);
  for (final bytes in shots) {
    await queue.enqueue(
      bytes: bytes,
      module: 'tasks',
      kind: kind.wire,
      entityType: checklistEntity,
      entityId: item.id,
    );
  }
  return shots.length;
}

/// Visor a pantalla completa; permite quitar una foto que aún no sube.
Future<void> showPhotoViewer(BuildContext context, WidgetRef ref, ItemPhoto photo) {
  final removable = photo.local != null && photo.local!.status != UploadStatus.done;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              child: Image(image: photoImage(ref, photo), fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: IconButton(
                tooltip: 'Cerrar',
                color: Colors.white,
                icon: const Icon(CustomIcons.close),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Row(
                children: [
                  _Pill(text: photo.kind.label),
                  const SizedBox(width: 8),
                  _Pill(
                    text: switch (photoStatus(photo)) {
                      PhotoUploadStatus.queued => 'En cola',
                      PhotoUploadStatus.uploading => 'Subiendo…',
                      PhotoUploadStatus.error => photo.local?.lastError ?? 'No se pudo subir',
                      _ => 'Subida',
                    },
                  ),
                  const Spacer(),
                  if (photo.failed)
                    TextButton(
                      onPressed: () {
                        ref.read(uploadQueueProvider).retry(photo.local!.id);
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                    ),
                  if (removable)
                    TextButton(
                      onPressed: () {
                        ref.read(uploadQueueProvider).remove(photo.local!.id);
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Eliminar', style: TextStyle(color: CustomColors.errorOnDark)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CustomTypography.bodySmall.copyWith(color: Colors.white),
      ),
    ),
  );
}
