import 'package:design_system/atoms/app_checkbox.dart';
import 'package:design_system/atoms/app_icon_button.dart';
import 'package:design_system/atoms/photo_thumb.dart';
import 'package:design_system/molecules/photo_grid.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_motion.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Fila de checklist ARGOS — casilla grande, texto, miniaturas de las fotos
/// del ítem y botón de cámara. Si el ítem exige foto, la casilla no se
/// puede marcar hasta tenerla.
/// Ref: ux-ui.md §2.6 (ChecklistItemRow) y B4.
class ChecklistItemRow extends StatelessWidget {
  const ChecklistItemRow({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
    this.description,
    this.photos = const [],
    this.requiresPhoto = false,
    this.onTakePhoto,
    this.onOpenPhoto,
  });

  final String label;
  final bool checked;

  /// Si es null el ítem es de solo lectura.
  final ValueChanged<bool>? onChanged;

  /// Indicación breve bajo el texto ("Incluye debajo de la cama").
  final String? description;
  final List<PhotoItem> photos;
  final bool requiresPhoto;
  final VoidCallback? onTakePhoto;
  final ValueChanged<int>? onOpenPhoto;

  bool get _blockedByPhoto => requiresPhoto && photos.isEmpty && !checked;

  @override
  Widget build(BuildContext context) {
    final duration = CustomMotion.resolve(context, CustomMotion.base);
    return AnimatedContainer(
      duration: duration,
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      decoration: BoxDecoration(
        color: checked ? CustomColors.surfaceSoft : CustomColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCheckbox(
            value: checked,
            semanticLabel: label,
            onChanged: onChanged == null || _blockedByPhoto ? null : onChanged,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: CustomTypography.verdana(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                      color: checked
                          ? CustomColors.textSecondary
                          : CustomColors.textPrimary,
                    ),
                    child: Text(label),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: CustomTypography.bodySmall.copyWith(
                        color: CustomColors.textSecondary,
                      ),
                    ),
                  ],
                  if (_blockedByPhoto) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          CustomIcons.camera,
                          size: 14,
                          color: CustomColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Requiere foto',
                          style: CustomTypography.verdana(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: CustomColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (photos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < photos.length; i++)
                          PhotoThumb(
                            size: 52,
                            image: photos[i].image,
                            status: photos[i].status,
                            progress: photos[i].progress,
                            onRetry: photos[i].onRetry,
                            onTap: onOpenPhoto == null
                                ? null
                                : () => onOpenPhoto!(i),
                            semanticLabel: 'Foto ${i + 1} de $label',
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (onTakePhoto != null)
            AppIconButton(
              icon: CustomIcons.camera,
              semanticLabel: 'Tomar foto de $label',
              color: requiresPhoto && photos.isEmpty
                  ? CustomColors.secondary
                  : CustomColors.tealMuted,
              onPressed: onTakePhoto,
            ),
        ],
      ),
    );
  }
}
