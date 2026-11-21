import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _before = AssetImage('assets/demo/room_before.jpg');
const _after = AssetImage('assets/demo/room_after.jpg');

/// Catálogo de componentes del design system con datos de ejemplo, para
/// revisarlos en el teléfono. Solo aparece en Perfil en modo de pruebas
/// (ARGOS_MOCK) o en compilaciones de depuración.
class ComponentCatalogPage extends StatefulWidget {
  const ComponentCatalogPage({super.key});

  @override
  State<ComponentCatalogPage> createState() => _ComponentCatalogPageState();
}

class _ComponentCatalogPageState extends State<ComponentCatalogPage> {
  var _filter = <String>{'hoy'};
  var _search = '';
  var _amount = 2;
  final _checks = <int, bool>{0: true, 1: false, 2: false};
  var _photoCount = 0;
  var _returned = 3;
  var _consumed = 1;

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 8),
          Text(
            'Buscando "$_search"',
            style: CustomTypography.bodySmall.copyWith(
              color: CustomColors.textSecondary,
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
                photos: [
                  for (var i = 0; i < _photoCount; i++)
                    const PhotoItem(image: _after),
                ],
                onTakePhoto: () => setState(() => _photoCount++),
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

class _DetailDemo extends StatelessWidget {
  const _DetailDemo();

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      overline: 'LAU-01 · Limpieza de salida',
      title: 'Casa Laurel',
      subtitle: 'Hoy · 10:00 a 13:00',
      status: const StatusBadge(
        label: 'Retrasada',
        variant: StatusBadgeVariant.inProgress,
      ),
      banner: const DetailBanner(message: 'Debió iniciar a las 09:00'),
      onBack: () => Navigator.of(context).pop(),
      footer: PrimaryButton(label: 'Iniciar limpieza', onPressed: () {}),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dirección', style: CustomTypography.label),
              const SizedBox(height: 6),
              Text(
                'Calle de los Laureles 14, Escazú',
                style: CustomTypography.body,
              ),
              const SizedBox(height: 14),
              TertiaryButton(label: 'Cómo llegar', onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Checklist', style: CustomTypography.label),
              const SizedBox(height: 8),
              Text('3 secciones · 18 ítems', style: CustomTypography.cardTitle),
              const SizedBox(height: 12),
              const ProgressBar(value: 0),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Línea de tiempo', style: CustomTypography.sectionTitle),
        const SizedBox(height: 16),
        const TimelineItem(
          title: 'Tarea asignada',
          detail: 'Por Ana Rodríguez',
          time: 'ayer',
          isFirst: true,
        ),
        const TimelineItem(
          title: 'Check-out del huésped',
          time: '08:40',
          icon: CustomIcons.reservations,
          tone: TimelineTone.info,
          isLast: true,
        ),
      ],
    );
  }
}
