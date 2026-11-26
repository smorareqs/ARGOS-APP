import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/hospitality/data/hospitality_repository.dart';
import 'package:argos_app/features/hospitality/models/reservation.dart';
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

/// Áreas de la plantilla de inspección.
const inspectionAreas = ['Sala', 'Cocina', 'Dormitorio principal', 'Baño principal', 'Otros dormitorios', 'Exterior'];

class _DraftFinding {
  _DraftFinding({
    required this.area,
    required this.description,
    required this.severity,
    required this.photos,
    this.cost,
    this.charge = false,
    this.ticket = false,
  });

  final String area;
  final String description;
  final String severity;
  final double? cost;
  final bool charge;
  final bool ticket;
  final DraftPhotos photos;
}

/// C10 · Inspección antes de la llegada o después de la salida: fotos por
/// área (con las de la inspección anterior para comparar) y hallazgos.
class InspectionPage extends ConsumerStatefulWidget {
  const InspectionPage({super.key, required this.reservationId, required this.kind});

  final String reservationId;

  /// `pre_arrival` o `post_departure`.
  final String kind;

  @override
  ConsumerState<InspectionPage> createState() => _InspectionPageState();
}

class _InspectionPageState extends ConsumerState<InspectionPage> {
  final _draft = const Uuid().v4();
  late final _areas = {for (final a in inspectionAreas) a: DraftPhotos('$_draft-$a', entity: 'inspection')};
  final _findings = <_DraftFinding>[];
  final _notes = TextEditingController();
  late final UploadQueue _queue;
  var _busy = false;
  var _sent = false;

  bool get _post => widget.kind == 'post_departure';

  @override
  void initState() {
    super.initState();
    _queue = ref.read(uploadQueueProvider);
  }

  @override
  void dispose() {
    if (!_sent) {
      for (final p in _areas.values) {
        p.discard(_queue);
      }
      for (final f in _findings) {
        f.photos.discard(_queue);
      }
    }
    _notes.dispose();
    super.dispose();
  }

  List<PendingUpload> _all() => [
    for (final p in _areas.values) ...p.of(ref),
    for (final f in _findings) ...f.photos.of(ref),
  ];

  Future<void> _addFinding(String propertyCode) async {
    final f = await showArgosSheet<_DraftFinding>(
      context,
      builder: (_) => _FindingSheet(draft: _draft, index: _findings.length, propertyCode: propertyCode, post: _post),
    );
    if (f != null) setState(() => _findings.add(f));
  }

  Future<void> _save(ReservationDetail d) async {
    final all = _all();
    if (!DraftPhotos.allUploaded(all)) {
      showToast(context, 'Espera a que terminen de subir las fotos.');
      return;
    }
    final photos = [for (final p in _areas.values) ...DraftPhotos.fileIds(p.of(ref))];
    if (photos.isEmpty && _findings.isEmpty) {
      showToast(context, 'Toma al menos una foto o registra un hallazgo.');
      return;
    }
    setState(() => _busy = true);
    final repo = ref.read(hospitalityRepositoryProvider);
    try {
      var detail = await repo.createInspection(d.reservation.id, kind: widget.kind, notes: _notes.text, photoIds: photos);
      final inspection = detail.inspection(widget.kind);
      if (inspection != null) {
        for (final f in _findings) {
          detail = await repo.addFinding(
            inspection.id,
            area: f.area,
            description: f.description,
            severity: f.severity,
            cost: f.cost,
            charge: f.charge,
            createTicket: f.ticket,
            photoIds: DraftPhotos.fileIds(f.photos.of(ref)),
          );
        }
      }
      _sent = true;
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      final tickets = _findings.where((f) => f.ticket).length;
      showToast(
        context,
        tickets == 0 ? 'Inspección guardada.' : 'Inspección guardada. Se ${tickets == 1 ? 'creó 1 incidencia' : 'crearon $tickets incidencias'}.',
      );
      context.pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, errorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reservationDetailProvider(widget.reservationId));
    final d = async.valueOrNull;
    if (d == null) {
      return Scaffold(
        backgroundColor: CustomColors.background,
        body: Center(
          child: async.isLoading
              ? const CircularProgressIndicator(color: CustomColors.secondary)
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorState(
                    message: errorMessage(async.error ?? 'Error'),
                    onRetry: () => ref.invalidate(reservationDetailProvider(widget.reservationId)),
                  ),
                ),
        ),
      );
    }
    final r = d.reservation;
    final before = _post ? d.inspection('pre_arrival') : null;
    final all = _all();
    final uploading = !DraftPhotos.allUploaded(all);
    final charges = _findings.where((f) => f.charge).fold<double>(0, (s, f) => s + (f.cost ?? 0));

    return FormScaffold(
      title: _post ? 'Inspección de salida' : 'Antes de la llegada',
      subtitle: '${r.propertyCode} · ${r.propertyName}',
      onBack: () => context.pop(),
      footer: PrimaryButton(
        label: uploading ? 'Subiendo fotos…' : 'Guardar inspección',
        isLoading: _busy,
        onPressed: uploading ? null : () => _save(d),
      ),
      children: [
        if (before != null && before.photos.isNotEmpty) ...[
          const SectionHeader(title: 'Cómo estaba al llegar'),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: before.photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  before.photos[i],
                  width: 120,
                  height: 92,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(width: 120, color: CustomColors.neutralSoft, child: const Icon(CustomIcons.photo)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],
        const SectionHeader(title: 'Fotos por área'),
        const SizedBox(height: 10),
        for (final entry in _areas.entries) ...[
          _AreaPhotos(area: entry.key, photos: entry.value, propertyCode: r.propertyCode),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 10),
        SectionHeader(title: _findings.isEmpty ? 'Hallazgos' : 'Hallazgos · ${_findings.length}'),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _findings.length; i++)
                AppListTile(
                  icon: CustomIcons.incident,
                  title: '${_findings[i].area} · ${switch (_findings[i].severity) {
                    'high' => 'grave',
                    'medium' => 'moderado',
                    _ => 'leve',
                  }}',
                  subtitle: [
                    _findings[i].description,
                    if (_findings[i].cost != null) money(_findings[i].cost!, r.currency),
                    if (_findings[i].charge) 'al depósito',
                    if (_findings[i].ticket) 'crea incidencia',
                  ].join(' · '),
                  trailing: IconButton(
                    tooltip: 'Quitar hallazgo',
                    icon: const Icon(CustomIcons.close, size: 18, color: CustomColors.textMuted),
                    onPressed: () async {
                      final f = _findings[i];
                      setState(() => _findings.removeAt(i));
                      await f.photos.discard(_queue);
                    },
                  ),
                  showChevron: false,
                ),
              AppListTile(icon: CustomIcons.add, title: 'Agregar hallazgo', onTap: () => _addFinding(r.propertyCode), showChevron: false),
            ],
          ),
        ),
        if (charges > 0) ...[
          const SizedBox(height: 10),
          Text('Cargo estimado al depósito: ${money(charges, r.currency)}', style: CustomTypography.bodySmall.copyWith(color: CustomColors.error)),
        ],
        const SizedBox(height: 18),
        LabeledField(
          label: 'Notas (opcional)',
          field: AppTextField(controller: _notes, maxLines: 3, hintText: 'Algo que deba saber el equipo'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AreaPhotos extends ConsumerWidget {
  const _AreaPhotos({required this.area, required this.photos, required this.propertyCode});

  final String area;
  final DraftPhotos photos;
  final String propertyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = photos.of(ref);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(area, style: CustomTypography.cardTitle.copyWith(fontSize: 15.5))),
              if (list.isNotEmpty) Text('${list.length} ${list.length == 1 ? 'foto' : 'fotos'}', style: CustomTypography.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          DraftPhotoGrid(
            photos: list,
            addLabel: list.isEmpty ? 'Fotografiar' : 'Otra',
            onAdd: () => photos.take(
              context,
              ref,
              module: 'reservations',
              kind: 'inspection_photo',
              title: area,
              propertyCode: propertyCode,
            ),
          ),
        ],
      ),
    );
  }
}

class _FindingSheet extends ConsumerStatefulWidget {
  const _FindingSheet({required this.draft, required this.index, required this.propertyCode, required this.post});

  final String draft;
  final int index;
  final String propertyCode;
  final bool post;

  @override
  ConsumerState<_FindingSheet> createState() => _FindingSheetState();
}

class _FindingSheetState extends ConsumerState<_FindingSheet> {
  late final _photos = DraftPhotos('${widget.draft}-f${widget.index}-${const Uuid().v4()}', entity: 'inspection');
  final _description = TextEditingController();
  final _cost = TextEditingController();
  var _area = inspectionAreas.first;
  var _severity = 'low';
  var _charge = false;
  var _ticket = false;
  var _kept = false;
  String? _error;
  late final UploadQueue _queue;

  @override
  void initState() {
    super.initState();
    _queue = ref.read(uploadQueueProvider);
  }

  @override
  void dispose() {
    if (!_kept) _photos.discard(_queue);
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _add() {
    if (_description.text.trim().length < 3) {
      setState(() => _error = 'Describe el hallazgo.');
      return;
    }
    final cost = double.tryParse(_cost.text.replaceAll(',', '.').trim());
    _kept = true;
    Navigator.of(context).pop(
      _DraftFinding(
        area: _area,
        description: _description.text.trim(),
        severity: _severity,
        cost: cost,
        charge: _charge && cost != null,
        ticket: _ticket,
        photos: _photos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Agregar hallazgo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ÁREA', style: CustomTypography.label.copyWith(color: CustomColors.textSecondary)),
          const SizedBox(height: 8),
          FilterChips<String>(
            padding: EdgeInsets.zero,
            options: [for (final a in inspectionAreas) FilterOption(value: a, label: a)],
            selected: {_area},
            onChanged: (s) => setState(() => _area = s.isEmpty ? _area : s.first),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Qué encontraste',
            field: AppTextField(controller: _description, maxLines: 2, hintText: 'Mancha en el sofá, vaso roto…'),
          ),
          const SizedBox(height: 12),
          Text('GRAVEDAD', style: CustomTypography.label.copyWith(color: CustomColors.textSecondary)),
          const SizedBox(height: 8),
          FilterChips<String>(
            padding: EdgeInsets.zero,
            options: const [
              FilterOption(value: 'low', label: 'Leve'),
              FilterOption(value: 'medium', label: 'Moderado'),
              FilterOption(value: 'high', label: 'Grave'),
            ],
            selected: {_severity},
            onChanged: (s) => setState(() => _severity = s.isEmpty ? _severity : s.first),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Costo estimado (opcional)',
            field: AppTextField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: CustomIcons.deposit,
            ),
          ),
          if (widget.post)
            _ToggleRow(label: 'Cobrar al depósito', value: _charge, onChanged: (v) => setState(() => _charge = v)),
          _ToggleRow(label: 'Crear incidencia de mantenimiento', value: _ticket, onChanged: (v) => setState(() => _ticket = v)),
          const SizedBox(height: 8),
          DraftPhotoGrid(
            photos: _photos.of(ref),
            addLabel: 'Foto',
            onAdd: () => _photos.take(
              context,
              ref,
              module: 'reservations',
              kind: 'inspection_photo',
              title: 'Hallazgo · $_area',
              propertyCode: widget.propertyCode,
              maxPhotos: 3,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: CustomTypography.bodySmall.copyWith(color: CustomColors.error)),
          ],
          const SizedBox(height: 16),
          PrimaryButton(label: 'Agregar', onPressed: _add),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: CustomTypography.body)),
          AppToggle(value: value, onChanged: onChanged, semanticLabel: label),
        ],
      ),
    );
  }
}
