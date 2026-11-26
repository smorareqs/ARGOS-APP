import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/tickets/data/tickets_repository.dart';
import 'package:argos_app/features/tickets/models/ticket.dart';
import 'package:argos_app/features/tickets/presentation/widgets/draft_photos.dart';
import 'package:argos_app/features/uploads/data/repositories/upload_queue.dart';
import 'package:argos_app/features/uploads/models/pending_upload.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// B14 · Detalle de incidencia: estado y urgencia, lo reportado con fotos,
/// el activo, la solución y la línea de tiempo. Mantenimiento la inicia y la
/// resuelve (qué se hizo, costo y fotos).
class TicketDetailPage extends ConsumerStatefulWidget {
  const TicketDetailPage({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  var _busy = false;

  Future<void> _refresh() =>
      ref.refresh(ticketDetailProvider(widget.ticketId).future).then((_) {}, onError: (_) {});

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      await ref.read(ticketsRepositoryProvider).start(widget.ticketId);
      if (!mounted) return;
      showToast(context, 'Incidencia en curso.');
      await _refresh();
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resolve(Ticket t) async {
    final done = await showArgosSheet<bool>(context, builder: (_) => _ResolveSheet(ticket: t));
    if (done == true && mounted) {
      showToast(context, '¡Listo! Incidencia #${t.number} resuelta.');
      ref.invalidate(ticketListProvider);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ticketDetailProvider(widget.ticketId));
    final detail = async.valueOrNull;
    if (detail == null) {
      return DetailScaffold(
        title: async.hasError ? 'Incidencia' : 'Cargando…',
        onBack: () => context.pop(),
        children: [
          if (async.hasError)
            ErrorState(message: errorMessage(async.error!), onRetry: _refresh)
          else
            for (var i = 0; i < 3; i++) ...[
              const Skeleton(width: double.infinity, height: 96, radius: CustomDimensions.radiusCard),
              const SizedBox(height: 12),
            ],
        ],
      );
    }

    final t = detail.ticket;
    final auth = ref.watch(sessionControllerProvider);
    final me = auth is AuthSignedIn ? auth.session.user.id : null;
    final canExecute = auth is AuthSignedIn && auth.session.can('maintenance.execute');
    final mineOrFree = t.assigneeId == null || t.assigneeId == me;
    final reportPhotos = detail.photos.where((p) => p.stage != 'resolution').toList();
    final fixPhotos = detail.photos.where((p) => p.stage == 'resolution').toList();

    Widget? footer;
    if (canExecute && mineOrFree) {
      if (t.status == TicketStatus.open || t.status == TicketStatus.assigned) {
        footer = PrimaryButton(label: 'Iniciar', isLoading: _busy, onPressed: _busy ? null : _start);
      } else if (t.status == TicketStatus.inProgress) {
        footer = PrimaryButton(label: 'Resolver', onPressed: () => _resolve(t));
      }
    }

    return RefreshIndicator(
      color: CustomColors.primary,
      onRefresh: _refresh,
      child: DetailScaffold(
        overline: '#${t.number} · Urgencia ${t.urgency.label.toLowerCase()}',
        title: t.title,
        subtitle: t.place.isEmpty ? null : t.place,
        status: StatusBadge(label: t.status.label, variant: t.status.badge),
        banner: t.urgency == Urgency.critical && t.status.active
            ? const DetailBanner(
                message: 'Urgencia crítica: atiéndela lo antes posible.',
                icon: CustomIcons.incident,
                background: CustomColors.errorSoft,
                foreground: CustomColors.error,
              )
            : null,
        onBack: () => context.pop(),
        footer: footer,
        children: [
          _Card(
            icon: CustomIcons.incident,
            label: 'Lo reportado',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description.isEmpty ? 'Sin descripción.' : t.description,
                  style: CustomTypography.body,
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (t.reporterName != null) t.reporterName! else 'Preventivo',
                    DateLabels.relative(t.createdAt),
                  ].join(' · '),
                  style: CustomTypography.bodySmall,
                ),
                if (reportPhotos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _NetworkPhotos(photos: reportPhotos),
                ],
              ],
            ),
          ),
          if (t.assetName != null) ...[
            const SizedBox(height: 12),
            _Card(
              icon: CustomIcons.maintenance,
              label: 'Equipo',
              child: Text(t.assetName!, style: CustomTypography.body),
            ),
          ],
          if (t.assigneeName != null || t.vendorName != null) ...[
            const SizedBox(height: 12),
            _Card(
              icon: CustomIcons.person,
              label: 'Atiende',
              child: Text(
                [?t.assigneeName, if (t.vendorName != null) 'Proveedor: ${t.vendorName}'].join(' · '),
                style: CustomTypography.body,
              ),
            ),
          ],
          if (t.resolution != null) ...[
            const SizedBox(height: 12),
            _Card(
              icon: CustomIcons.done,
              label: 'Solución',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.resolution!, style: CustomTypography.body),
                  if (t.cost != null) ...[
                    const SizedBox(height: 6),
                    Text('Costo: Q ${t.cost!.toStringAsFixed(2)}', style: CustomTypography.bodySmall),
                  ],
                  if (fixPhotos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _NetworkPhotos(photos: fixPhotos),
                  ],
                ],
              ),
            ),
          ],
          if (detail.events.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Historial', style: CustomTypography.sectionTitle),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  for (final (i, e) in detail.events.indexed)
                    TimelineItem(
                      title: e.title,
                      time: DateLabels.relative(e.createdAt),
                      detail: e.detail,
                      tone: e.tone,
                      isFirst: i == 0,
                      isLast: i == detail.events.length - 1,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.label, required this.child});

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: CustomColors.tealWashed, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: CustomColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: CustomTypography.label),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ],
    ),
  );
}

class _NetworkPhotos extends StatelessWidget {
  const _NetworkPhotos({required this.photos});

  final List<TicketPhoto> photos;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final p in photos)
        PhotoThumb(
          image: NetworkImage(p.url),
          semanticLabel: 'Foto de la incidencia',
          onTap: () => showDialog<void>(
            context: context,
            barrierColor: Colors.black87,
            builder: (dialogContext) => Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  Positioned.fill(child: InteractiveViewer(child: Image.network(p.url, fit: BoxFit.contain))),
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
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

/// Hoja "Resolver": qué se hizo, costo opcional, fotos y si el equipo quedó
/// funcionando.
class _ResolveSheet extends ConsumerStatefulWidget {
  const _ResolveSheet({required this.ticket});

  final Ticket ticket;

  @override
  ConsumerState<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends ConsumerState<_ResolveSheet> {
  late final _photos = DraftPhotos(const Uuid().v4());
  late final UploadQueue _queue;
  final _resolution = TextEditingController();
  final _cost = TextEditingController();
  var _operational = true;
  var _saving = false;
  var _sent = false;

  @override
  void initState() {
    super.initState();
    _queue = ref.read(uploadQueueProvider);
    _resolution.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (!_sent) _photos.discard(_queue);
    _resolution.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uploads = await ref.read(entityUploadsProvider(_photos.entityType, _photos.entityId).future);
    setState(() => _saving = true);
    try {
      await ref
          .read(ticketsRepositoryProvider)
          .resolve(
            widget.ticket.id,
            resolution: _resolution.text,
            cost: double.tryParse(_cost.text.replaceAll(',', '.')),
            photoIds: DraftPhotos.fileIds(uploads),
            assetOperational: widget.ticket.assetId != null && _operational,
          );
      _sent = true;
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos.of(ref);
    final failed = photos.any((p) => p.status == UploadStatus.error);
    final uploading = !DraftPhotos.allUploaded(photos);
    final ready = _resolution.text.trim().length >= 3 && !uploading && !failed;
    return SheetScaffold(
      title: 'Resolver #${widget.ticket.number}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: 'Qué se hizo',
            field: AppTextField(
              controller: _resolution,
              hintText: 'Ej.: Cambié el empaque de la llave y probé que no gotea.',
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Costo en quetzales (opcional)',
            field: TextField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(hintText: '0.00', prefixText: 'Q '),
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Fotos de la solución',
            field: DraftPhotoGrid(
              photos: photos,
              onAdd: () => _photos.take(
                context,
                ref,
                module: 'maintenance',
                kind: 'ticket_resolution',
                title: 'Solución #${widget.ticket.number}',
                propertyCode: widget.ticket.propertyCode,
              ),
            ),
          ),
          if (widget.ticket.assetId != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text('${widget.ticket.assetName ?? 'El equipo'} quedó funcionando', style: CustomTypography.body),
                ),
                AppToggle(value: _operational, onChanged: (v) => setState(() => _operational = v)),
              ],
            ),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: uploading ? 'Subiendo fotos…' : 'Marcar como resuelta',
            isLoading: _saving,
            onPressed: ready && !_saving ? _save : null,
          ),
        ],
      ),
    );
  }
}
