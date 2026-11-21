import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Estado de subida de una foto (ux-ui.md §3.4).
enum PhotoUploadStatus { none, queued, uploading, done, error }

/// Miniatura de foto ARGOS — cuadrada de 72 px con radio 12 y el estado de
/// subida encima: en cola, subiendo con porcentaje, lista o error con
/// reintento.
/// Ref: ux-ui.md §2.4 (Fotos), §2.6 (PhotoThumb) y §3.4.
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({
    super.key,
    required this.image,
    this.status = PhotoUploadStatus.none,
    this.progress,
    this.size = 72,
    this.onTap,
    this.onRetry,
    this.semanticLabel = 'Foto',
  });

  final ImageProvider image;
  final PhotoUploadStatus status;

  /// 0–1, solo con [PhotoUploadStatus.uploading].
  final double? progress;
  final double size;
  final VoidCallback? onTap;

  /// Con [PhotoUploadStatus.error], tocar la miniatura reintenta.
  final VoidCallback? onRetry;
  final String semanticLabel;

  String get _statusText => switch (status) {
    PhotoUploadStatus.none => '',
    PhotoUploadStatus.queued => 'en cola',
    PhotoUploadStatus.uploading =>
      'subiendo ${((progress ?? 0) * 100).round()} %',
    PhotoUploadStatus.done => 'subida',
    PhotoUploadStatus.error => 'error al subir, toca para reintentar',
  };

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final tap = status == PhotoUploadStatus.error && onRetry != null
        ? onRetry
        : onTap;

    return Semantics(
      button: tap != null,
      label: [semanticLabel, _statusText].where((s) => s.isNotEmpty).join(', '),
      child: GestureDetector(
        onTap: tap,
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(
                  image: image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: CustomColors.tealWashed,
                    child: Icon(
                      CustomIcons.photo,
                      color: CustomColors.tealMuted,
                    ),
                  ),
                ),
                if (status == PhotoUploadStatus.queued ||
                    status == PhotoUploadStatus.uploading ||
                    status == PhotoUploadStatus.error)
                  const ColoredBox(color: Color(0x66003841)),
                _overlay(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: status == PhotoUploadStatus.error
                          ? CustomColors.error
                          : const Color(0x14003841),
                      width: status == PhotoUploadStatus.error ? 2 : 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _overlay() {
    switch (status) {
      case PhotoUploadStatus.none:
        return const SizedBox.shrink();
      case PhotoUploadStatus.queued:
        return const Center(
          child: Icon(CustomIcons.uploadQueued, color: Colors.white, size: 24),
        );
      case PhotoUploadStatus.uploading:
        final value = progress?.clamp(0.0, 1.0);
        return Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 3,
                  color: CustomColors.secondary,
                  backgroundColor: const Color(0x55FFFFFF),
                ),
                if (value != null)
                  Text(
                    '${(value * 100).round()}',
                    style: CustomTypography.verdana(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      case PhotoUploadStatus.done:
        return Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: CustomColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(CustomIcons.done, size: 12, color: Colors.white),
          ),
        );
      case PhotoUploadStatus.error:
        return const Center(
          child: Icon(CustomIcons.retry, color: Colors.white, size: 26),
        );
    }
  }
}
