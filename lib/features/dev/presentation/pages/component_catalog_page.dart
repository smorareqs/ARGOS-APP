import 'dart:io';

import 'package:argos_app/features/camera/presentation/pages/camera_page.dart';
import 'package:argos_app/features/tasks/data/repositories/tasks_repository.dart';
import 'package:argos_app/features/tasks/models/task_detail.dart';
import 'package:argos_app/features/tasks/presentation/pages/task_detail_page.dart';
import 'package:argos_app/features/uploads/models/pending_upload.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _before = AssetImage('assets/demo/room_before.jpg');
const _after = AssetImage('assets/demo/room_after.jpg');

/// Catálogo de componentes del design system con datos de ejemplo, para
/// revisarlos en el teléfono. Solo aparece en Perfil en modo de pruebas
/// (ARGOS_MOCK) o en compilaciones de depuración.
///
/// El ítem "Tender la cama" usa la cámara y la cola de subida de verdad: la
/// foto se comprime, lleva marca de agua y se sube (al backend simulado en
/// modo de pruebas).
class ComponentCatalogPage extends ConsumerStatefulWidget {
  const ComponentCatalogPage({super.key});

  @override
  ConsumerState<ComponentCatalogPage> createState() =>
      _ComponentCatalogPageState();
}

const _demoEntityType = 'demo_checklist_item';
const _demoProperties = [
  'Casa Laurel',
  'Apartamento Olivo 3B',
  'Villa Cedro',
  'Loft Pino',
  'Casa Roble',
  'Cabaña Almendro',
];
const _demoEntityId = 'tender-cama';

class _ComponentCatalogPageState extends ConsumerState<ComponentCatalogPage> {
  var _filter = <String>{'hoy'};
  var _search = '';
  var _amount = 2;
  final _checks = <int, bool>{0: true, 1: false, 2: false};
  var _returned = 3;
  var _consumed = 1;

  Future<void> _takePhotos({ImageProvider? reference}) async {
    final photos = await openCamera(
      context,
      CameraRequest(
        title: 'Tender la cama',
        propertyCode: 'LAU-01',
        reference: reference,
      ),
    );
    if (photos == null) return;
    final queue = ref.read(uploadQueueProvider);
    for (final bytes in photos) {
      await queue.enqueue(
        bytes: bytes,
        module: 'cleaning',
        kind: 'checklist_photo',
        entityType: _demoEntityType,
        entityId: _demoEntityId,
      );
    }
  }

  List<PhotoItem> _photoItems(List<PendingUpload> uploads) => [
    for (final u in uploads)
      PhotoItem(
        image: FileImage(File(u.localPath)),
        status: switch (u.status) {
          UploadStatus.queued => PhotoUploadStatus.queued,
          UploadStatus.uploading => PhotoUploadStatus.uploading,
          UploadStatus.done => PhotoUploadStatus.done,
          UploadStatus.error => PhotoUploadStatus.error,
        },
        progress: u.progress,
        onRetry: () => ref.read(uploadQueueProvider).retry(u.id),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final uploads =
        ref
            .watch(entityUploadsProvider(_demoEntityType, _demoEntityId))
            .value ??
        const <PendingUpload>[];
    final photos = _photoItems(uploads);
    return FormScaffold(
      title: 'Componentes',
      subtitle: 'Piezas del design system con datos de ejemplo.',
      onBack: () => context.pop(),
      children: [
        const SectionHeader(number: '01', title: 'Búsqueda y filtros'),
        const SizedBox(height: 16),
        SearchField(
          hintText: 'Buscar propiedad',
          onSearch: (q) => setState(() => _search = q),
        ),
        if (_search.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final name in _demoProperties.where(
            (p) => p.toLowerCase().contains(_search.toLowerCase()),
          ))
            AppListTile(icon: CustomIcons.property, title: name, showChevron: false),
          if (!_demoProperties.any(
            (p) => p.toLowerCase().contains(_search.toLowerCase()),
          ))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin resultados para "$_search". Toca la ✕ para limpiar.',
                style: CustomTypography.bodySmall.copyWith(
                  color: CustomColors.textSecondary,
                ),
              ),
            ),
        ],
        const SizedBox(height: 12),
        FilterChips<String>(
          padding: EdgeInsets.zero,
          options: const [
            FilterOption(value: 'hoy', label: 'Hoy', count: 4),
            FilterOption(value: 'semana', label: 'Semana', count: 12),
            FilterOption(value: 'retrasadas', label: 'Retrasadas', count: 1),
          ],
          selected: _filter,
          onChanged: (s) => setState(() => _filter = s),
        ),
        const SizedBox(height: 32),
        const SectionHeader(number: '02', title: 'Cantidades'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('Toallas grandes', style: CustomTypography.cardTitle),
            ),
            NumberStepper(
              value: _amount,
              max: 10,
              unit: 'uds',
              semanticLabel: 'Toallas grandes',
              onChanged: (v) => setState(() => _amount = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        QuantityRow(
          name: 'Jabón líquido',
          sku: 'INS-0142',
          unit: 'uds',
          custody: 5,
          returned: _returned,
          consumed: _consumed,
          onReturnedChanged: (v) => setState(() => _returned = v),
          onConsumedChanged: (v) => setState(() => _consumed = v),
        ),
        const SizedBox(height: 32),
        const SectionHeader(number: '03', title: 'Checklist'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              ChecklistItemRow(
                label: 'Ventilar la habitación',
                checked: _checks[0]!,
                onChanged: (v) => setState(() => _checks[0] = v),
              ),
              ChecklistItemRow(
                label: 'Tender la cama con sábanas limpias',
                description: 'Foto de la cama terminada',
                checked: _checks[1]!,
                requiresPhoto: true,
                photos: photos,
                onTakePhoto: _takePhotos,
                onChanged: (v) => setState(() => _checks[1] = v),
              ),
              ChecklistItemRow(
                label: 'Limpiar debajo de la cama',
                checked: _checks[2]!,
                onChanged: (v) => setState(() => _checks[2] = v),
                onTakePhoto: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const SectionHeader(number: '04', title: 'Fotos'),
        const SizedBox(height: 16),
        PhotoGrid(
          required: 4,
          onAdd: () {},
          photos: [
            const PhotoItem(image: _before, status: PhotoUploadStatus.done),
            const PhotoItem(
              image: _after,
              status: PhotoUploadStatus.uploading,
              progress: 0.6,
            ),
            PhotoItem(
              image: _before,
              status: PhotoUploadStatus.error,
              onRetry: () {},
            ),
          ],
        ),
        const SizedBox(height: 20),
        const BeforeAfterPair(before: _before, after: _after),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Probar cámara con guía "antes"',
          onPressed: () => _takePhotos(reference: _before),
        ),
        if (uploads.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Fotos tomadas en esta prueba',
            style: CustomTypography.label,
          ),
          const SizedBox(height: 10),
          PhotoGrid(photos: photos),
          const SizedBox(height: 8),
          TertiaryButton(
            label: 'Borrar fotos de prueba',
            onPressed: () async {
              final queue = ref.read(uploadQueueProvider);
              for (final u in uploads) {
                await queue.remove(u.id);
              }
            },
          ),
        ],
        const SizedBox(height: 32),
        const SectionHeader(number: '05', title: 'Historial'),
        const SizedBox(height: 16),
        const TimelineItem(
          title: 'Tarea asignada',
          detail: 'Por Ana Rodríguez',
          time: 'ayer',
          isFirst: true,
        ),
        const TimelineItem(
          title: 'Limpieza iniciada',
          time: '09:12',
          icon: CustomIcons.play,
          tone: TimelineTone.info,
        ),
        const TimelineItem(
          title: 'Falta jabón líquido',
          detail: 'Se registró una diferencia de 1 unidad.',
          time: '10:05',
          icon: CustomIcons.incident,
          tone: TimelineTone.warning,
        ),
        const TimelineItem(
          title: 'Limpieza cerrada',
          time: '11:48',
          icon: CustomIcons.done,
          tone: TimelineTone.success,
          isLast: true,
        ),
        const SizedBox(height: 32),
        const SectionHeader(number: '06', title: 'Pantalla de detalle'),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Ver detalle de ejemplo',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const _DetailDemo()),
          ),
        ),
      ],
    );
  }
}

/// El detalle real (B3) con una tarea de ejemplo.
class _DetailDemo extends StatelessWidget {
  const _DetailDemo();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final iso = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final json = <String, dynamic>{
      'id': 'demo',
      'number': 128,
      'type': 'checkout_cleaning',
      'status': 'pending',
      'priority': 'high',
      'late': true,
      'date': iso,
      'start': '09:00',
      'end': '11:00',
      'notes': 'Check-out a las 08:40. Revisar la terraza y dejar toallas extra.',
      'property_id': 'demo',
      'property_code': 'LAU-01',
      'property_name': 'Casa Laurel',
      'property_address': 'Calle de los Laureles 14, Escazú',
      'reservation_code': 'R-2528',
      'items': [
        for (final (i, t) in ['Tender la cama', 'Reponer toallas', 'Desinfectar el baño'].indexed)
          {'id': 'i$i', 'section': i < 1 ? 'Habitación' : 'Baño', 'position': i, 'text': t, 'is_done': i == 0},
      ],
      'checklist': [
        {'name': 'Habitación', 'total': 1, 'done': 1},
        {'name': 'Baño', 'total': 2, 'done': 0},
      ],
      'can_execute': true,
    };
    return TaskDetailView(load: TaskLoad(task: TaskDetail.fromJson(json)));
  }
}
