import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/tickets/data/tickets_repository.dart';
import 'package:argos_app/features/tickets/models/ticket.dart';
import 'package:argos_app/features/tickets/presentation/widgets/draft_photos.dart';
import 'package:argos_app/features/tickets/presentation/widgets/picker_field.dart';
import 'package:argos_app/features/uploads/data/repositories/upload_queue.dart';
import 'package:argos_app/features/uploads/models/pending_upload.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// B12 · Reportar incidencia: propiedad (fija si viene de una tarea), activo,
/// urgencia, título, descripción y fotos. Las fotos suben mientras se
/// escribe; el reporte sale cuando todas están arriba.
class ReportTicketPage extends ConsumerStatefulWidget {
  const ReportTicketPage({super.key, this.propertyId, this.propertyLabel});

  final String? propertyId;

  /// "TB-504 · Torre Bosque" para mostrar sin esperar la lista.
  final String? propertyLabel;

  @override
  ConsumerState<ReportTicketPage> createState() => _ReportTicketPageState();
}

class _ReportTicketPageState extends ConsumerState<ReportTicketPage> {
  late final _photos = DraftPhotos(const Uuid().v4());
  final _title = TextEditingController();
  final _description = TextEditingController();
  PropertyOption? _property;
  AssetOption? _asset;
  var _urgency = Urgency.medium;
  var _sending = false;
  var _sent = false;
  late final UploadQueue _queue;

  @override
  void initState() {
    super.initState();
    _queue = ref.read(uploadQueueProvider); // en dispose ya no hay ref
    if (widget.propertyId != null) {
      final parts = (widget.propertyLabel ?? '').split(' · ');
      _property = PropertyOption(
        id: widget.propertyId!,
        code: parts.first,
        name: parts.length > 1 ? parts.sublist(1).join(' · ') : '',
      );
    }
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (!_sent) _photos.discard(_queue);
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickProperty(List<PropertyOption> list) async {
    final picked = await showOptionSheet<PropertyOption>(
      context,
      title: 'Propiedad',
      options: list,
      label: (p) => p.code,
      subtitle: (p) => p.name,
      searchable: list.length > 8,
    );
    final value = picked?.value;
    if (value != null && value.id != _property?.id) {
      setState(() {
        _property = value;
        _asset = null;
      });
    }
  }

  Future<void> _pickAsset(List<AssetOption> list) async {
    final sorted = [...list]..sort((a, b) {
      final c = AssetOption.categoryLabel(a.category).compareTo(AssetOption.categoryLabel(b.category));
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    final picked = await showOptionSheet<AssetOption>(
      context,
      title: 'Qué está fallando',
      options: sorted,
      label: (a) => a.name,
      subtitle: (a) => a.location ?? '',
      group: (a) => AssetOption.categoryLabel(a.category),
      searchable: list.length > 10,
      noneLabel: 'Otro / no está en la lista',
    );
    if (picked != null) setState(() => _asset = picked.value);
  }

  Future<void> _send() async {
    final property = _property;
    if (property == null) return;
    final uploads = await ref.read(entityUploadsProvider(_photos.entityType, _photos.entityId).future);
    setState(() => _sending = true);
    try {
      final created = await ref
          .read(ticketsRepositoryProvider)
          .create(
            propertyId: property.id,
            assetId: _asset?.id,
            title: _title.text,
            description: _description.text,
            urgency: _urgency.wire,
            photoIds: DraftPhotos.fileIds(uploads),
          );
      _sent = true;
      if (!mounted) return;
      ref.invalidate(ticketListProvider);
      showToast(context, 'Incidencia #${created.ticket.number} enviada. Mantenimiento ya la ve.');
      context.pop(created.ticket.id);
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fixed = widget.propertyId != null;
    final properties = fixed ? null : ref.watch(reportablePropertiesProvider);
    final property = _property;
    final assets = property == null ? null : ref.watch(propertyAssetsProvider(property.id));
    final photos = _photos.of(ref);
    final failed = photos.where((p) => p.status == UploadStatus.error).length;
    final uploading = !DraftPhotos.allUploaded(photos);
    final ready = property != null && _title.text.trim().length >= 3;

    String buttonLabel;
    if (failed > 0) {
      buttonLabel = 'Revisa las fotos que no subieron';
    } else if (uploading) {
      buttonLabel = 'Subiendo fotos…';
    } else {
      buttonLabel = 'Enviar reporte';
    }

    return FormScaffold(
      title: 'Reportar incidencia',
      subtitle: 'Cuéntanos qué pasa. Mantenimiento recibe el aviso al instante.',
      onBack: () => context.pop(),
      footer: PrimaryButton(
        label: buttonLabel,
        isLoading: _sending,
        onPressed: ready && !uploading && failed == 0 && !_sending ? _send : null,
      ),
      children: [
        LabeledField(
          label: 'Propiedad',
          field: switch (properties) {
            null => PickerField(
              value: property == null ? null : [property.code, if (property.name.isNotEmpty) property.name].join(' · '),
              placeholder: 'Propiedad',
              icon: CustomIcons.property,
            ),
            AsyncValue(:final valueOrNull?) => PickerField(
              value: property == null ? null : '${property.code} · ${property.name}',
              placeholder: valueOrNull.isEmpty ? 'No tienes propiedades asignadas' : 'Elige la propiedad',
              icon: CustomIcons.property,
              onTap: valueOrNull.isEmpty ? null : () => _pickProperty(valueOrNull),
            ),
            AsyncValue(:final error?) => ErrorState(
              message: errorMessage(error),
              onRetry: () => ref.invalidate(reportablePropertiesProvider),
            ),
            _ => const Skeleton(width: double.infinity, height: 52, radius: CustomDimensions.radiusField),
          },
        ),
        const SizedBox(height: 18),
        if (assets?.valueOrNull?.isNotEmpty ?? false) ...[
          LabeledField(
            label: 'Qué está fallando (opcional)',
            field: PickerField(
              value: _asset?.name,
              placeholder: 'Elige el equipo o la instalación',
              icon: CustomIcons.maintenance,
              onTap: () => _pickAsset(assets!.valueOrNull!),
            ),
          ),
          const SizedBox(height: 18),
        ],
        LabeledField(
          label: 'Urgencia',
          field: UrgencySelector(value: _urgency, onChanged: (u) => setState(() => _urgency = u)),
        ),
        const SizedBox(height: 18),
        LabeledField(
          label: 'Título',
          field: AppTextField(controller: _title, hintText: 'Ej.: Fuga de agua bajo el lavamanos'),
        ),
        const SizedBox(height: 18),
        LabeledField(
          label: 'Descripción (opcional)',
          field: AppTextField(
            controller: _description,
            hintText: 'Dónde está, desde cuándo, qué intentaste…',
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 18),
        LabeledField(
          label: 'Fotos',
          field: DraftPhotoGrid(
            photos: photos,
            onAdd: () => _photos.take(
              context,
              ref,
              module: 'maintenance',
              kind: 'ticket_photo',
              title: _title.text.trim().isEmpty ? 'Incidencia' : _title.text.trim(),
              propertyCode: property?.code,
            ),
          ),
        ),
      ],
    );
  }
}
