import 'package:design_system/atoms/photo_thumb.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Una foto dentro de [PhotoGrid] o [ChecklistItemRow].
class PhotoItem {
  const PhotoItem({
    required this.image,
    this.status = PhotoUploadStatus.none,
    this.progress,
    this.onRetry,
  });

  final ImageProvider image;
  final PhotoUploadStatus status;
  final double? progress;
  final VoidCallback? onRetry;
}

/// Rejilla de fotos ARGOS — miniaturas de 72 px con su estado de subida, el
/// conteo de requeridas ("3/5 fotos requeridas") y un botón para tomar más.
/// Ref: ux-ui.md §2.6 (PhotoGrid) y §3.4.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    this.required,
    this.onAdd,
    this.onOpen,
    this.addLabel = 'Tomar foto',
  });

  final List<PhotoItem> photos;

  /// Fotos mínimas; muestra el conteo y lo resalta mientras falten.
  final int? required;

  /// Abre la cámara. Si es null no se muestra el botón.
  final VoidCallback? onAdd;

  /// Abre el visor en la foto [index].
  final ValueChanged<int>? onOpen;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final missing = required != null && photos.length < required!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (required != null) ...[
          Row(
            children: [
              Icon(
                missing ? CustomIcons.camera : CustomIcons.check,
                size: 16,
                color: missing ? CustomColors.warning : CustomColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                '${photos.length}/$required fotos requeridas',
                style: CustomTypography.verdana(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: missing ? CustomColors.warning : CustomColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < photos.length; i++)
              PhotoThumb(
                image: photos[i].image,
                status: photos[i].status,
                progress: photos[i].progress,
                onRetry: photos[i].onRetry,
                onTap: onOpen == null ? null : () => onOpen!(i),
                semanticLabel: 'Foto ${i + 1} de ${photos.length}',
              ),
            if (onAdd != null) _AddPhotoTile(label: addLabel, onTap: onAdd!),
          ],
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: CustomColors.tealWashed,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(
            width: 72,
            height: 72,
            child: Icon(
              CustomIcons.camera,
              size: 28,
              color: CustomColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
