import 'dart:io';

import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/hospitality/data/hospitality_repository.dart';
import 'package:argos_app/features/tickets/presentation/widgets/draft_photos.dart';
import 'package:argos_app/features/uploads/data/repositories/upload_queue.dart';
import 'package:argos_app/features/uploads/models/pending_upload.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// C8 · Captura del documento: frente y reverso con marco de encuadre,
/// vista previa y subida. Cada foto se liga al huésped en cuanto termina de
/// subir (`POST /guests/{id}/documents`).
class GuestDocumentPage extends ConsumerStatefulWidget {
  const GuestDocumentPage({super.key, required this.guestId, this.guestName, this.propertyCode});

  final String guestId;
  final String? guestName;
  final String? propertyCode;

  @override
  ConsumerState<GuestDocumentPage> createState() => _GuestDocumentPageState();
}

class _GuestDocumentPageState extends ConsumerState<GuestDocumentPage> {
  late final _front = DraftPhotos('${widget.guestId}-front', entity: 'guest_document');
  late final _back = DraftPhotos('${widget.guestId}-back', entity: 'guest_document');
  late final UploadQueue _queue;
  final _attached = <String>{};
  final _attaching = <String>{};
  var _done = false;

  @override
  void initState() {
    super.initState();
    _queue = ref.read(uploadQueueProvider);
  }

  @override
  void dispose() {
    // Las fotos del documento no se quedan en el teléfono.
    _front.discard(_queue);
    _back.discard(_queue);
    super.dispose();
  }

  Future<void> _take(DraftPhotos photos, String kind) async {
    // Una sola foto por lado: la nueva reemplaza a la anterior.
    await photos.discard(_queue);
    setState(() => _attached.remove(kind));
    if (!mounted) return;
    await photos.take(
      context,
      ref,
      module: 'guests',
      kind: kind,
      title: kind == 'id_front' ? 'Frente del documento' : 'Reverso del documento',
      propertyCode: widget.propertyCode,
      maxPhotos: 1,
      documentGuide: true,
    );
  }

  /// Liga la foto al huésped cuando ya subió.
  void _attachWhenReady(String kind, List<PendingUpload> list) {
    final up = list.where((u) => u.status == UploadStatus.done && u.fileId != null).lastOrNull;
    if (up == null || _attached.contains(kind) || _attaching.contains(kind)) return;
    _attaching.add(kind);
    ref
        .read(hospitalityRepositoryProvider)
        .attachDocument(widget.guestId, kind, up.fileId!)
        .then((_) {
          if (mounted) setState(() => _attached.add(kind));
        })
        .catchError((Object e) {
          if (mounted) showToast(context, errorMessage(e));
        })
        .whenComplete(() => _attaching.remove(kind));
  }

  @override
  Widget build(BuildContext context) {
    final front = _front.of(ref);
    final back = _back.of(ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachWhenReady('id_front', front);
      _attachWhenReady('id_back', back);
    });
    final step = front.isEmpty ? 0 : (back.isEmpty ? 1 : 2);
    final ready = _attached.containsAll(const ['id_front', 'id_back']);

    return FormScaffold(
      title: 'Documento',
      subtitle: widget.guestName == null ? 'Frente y reverso' : '${widget.guestName} · frente y reverso',
      onBack: () => context.pop(),
      footer: PrimaryButton(
        label: ready ? 'Listo' : (step < 2 ? 'Fotografiar ${step == 0 ? 'frente' : 'reverso'}' : 'Subiendo…'),
        trailingIcon: ready ? CustomIcons.check : CustomIcons.camera,
        isLoading: step == 2 && !ready,
        onPressed: ready
            ? () {
                HapticFeedback.mediumImpact();
                _done = true;
                showToast(context, 'Documento guardado.');
                context.pop(_done);
              }
            : (step == 0 ? () => _take(_front, 'id_front') : (step == 1 ? () => _take(_back, 'id_back') : null)),
      ),
      children: [
        ProgressBar(value: (_attached.length + (step > _attached.length ? 0.5 : 0)) / 2),
        const SizedBox(height: 18),
        Text(
          'Toma la foto sobre una superficie lisa y con buena luz. Que se lean el nombre y el número.',
          style: CustomTypography.body,
        ),
        const SizedBox(height: 18),
        _Side(
          label: 'Frente',
          uploads: front,
          attached: _attached.contains('id_front'),
          onTake: () => _take(_front, 'id_front'),
          onRetry: (id) => _queue.retry(id),
        ),
        const SizedBox(height: 14),
        _Side(
          label: 'Reverso',
          uploads: back,
          attached: _attached.contains('id_back'),
          onTake: front.isEmpty ? null : () => _take(_back, 'id_back'),
          onRetry: (id) => _queue.retry(id),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(CustomIcons.lock, size: 16, color: CustomColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Solo lo ve quien administra huéspedes. Se borra solo 90 días después de la salida.',
                style: CustomTypography.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.label, required this.uploads, required this.attached, required this.onTake, required this.onRetry});

  final String label;
  final List<PendingUpload> uploads;
  final bool attached;
  final VoidCallback? onTake;
  final ValueChanged<String> onRetry;

  @override
  Widget build(BuildContext context) {
    final up = uploads.lastOrNull;
    final status = up?.status;
    return AspectRatio(
      aspectRatio: 1.586,
      child: Material(
        color: CustomColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: status == UploadStatus.error ? () => onRetry(up!.id) : onTake,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: attached ? CustomColors.success : CustomColors.borderField, width: attached ? 2 : 1),
            ),
            child: up == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CustomIcons.document, size: 36, color: onTake == null ? CustomColors.disabled : CustomColors.tealMuted),
                      const SizedBox(height: 8),
                      Text(label, style: CustomTypography.cardTitle.copyWith(fontSize: 16, color: onTake == null ? CustomColors.disabled : null)),
                      Text(onTake == null ? 'Primero el frente' : 'Toca para fotografiar', style: CustomTypography.bodySmall),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(up.localPath), fit: BoxFit.cover),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: switch (status) {
                              UploadStatus.error => CustomColors.error,
                              _ when attached => CustomColors.success,
                              _ => CustomColors.primary,
                            },
                            borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
                          ),
                          child: Text(
                            switch (status) {
                              UploadStatus.error => '$label · toca para reintentar',
                              _ when attached => '$label · guardado',
                              _ => '$label · subiendo…',
                            },
                            style: CustomTypography.label.copyWith(color: Colors.white, fontSize: 11.5),
                          ),
                        ),
                      ),
                      if (onTake != null)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: AppIconButton(icon: CustomIcons.retry, semanticLabel: 'Repetir foto del $label', onPressed: onTake),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
