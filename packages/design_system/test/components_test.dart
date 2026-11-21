import 'dart:convert';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// PNG 1×1 transparente para las fotos de prueba.
final _pixel = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  ),
);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('NumberStepper respeta mínimo y máximo', (tester) async {
    var value = 1;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _wrap(
          NumberStepper(
            value: value,
            max: 2,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(CustomIcons.add));
    await tester.pump();
    expect(value, 2);
    await tester.tap(find.byIcon(CustomIcons.add));
    await tester.pump();
    expect(value, 2, reason: 'no pasa del máximo');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(CustomIcons.remove));
      await tester.pump();
    }
    expect(value, 0, reason: 'no baja del mínimo');
  });

  testWidgets('ChecklistItemRow no se marca sin la foto requerida', (
    tester,
  ) async {
    bool? changed;
    await tester.pumpWidget(
      _wrap(
        ChecklistItemRow(
          label: 'Tender la cama',
          checked: false,
          requiresPhoto: true,
          onChanged: (v) => changed = v,
          onTakePhoto: () {},
        ),
      ),
    );
    expect(find.text('Requiere foto'), findsOneWidget);
    await tester.tap(find.byType(AppCheckbox));
    await tester.pump();
    expect(changed, isNull);

    await tester.pumpWidget(
      _wrap(
        ChecklistItemRow(
          label: 'Tender la cama',
          checked: false,
          requiresPhoto: true,
          photos: [PhotoItem(image: _pixel)],
          onChanged: (v) => changed = v,
        ),
      ),
    );
    await tester.tap(find.byType(AppCheckbox));
    await tester.pump();
    expect(changed, isTrue);
  });

  testWidgets('PhotoGrid muestra el conteo de fotos requeridas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PhotoGrid(
          photos: [
            PhotoItem(image: _pixel),
            PhotoItem(image: _pixel, status: PhotoUploadStatus.error),
          ],
          required: 3,
          onAdd: () {},
        ),
      ),
    );
    expect(find.text('2/3 fotos requeridas'), findsOneWidget);
    expect(find.byType(PhotoThumb), findsNWidgets(2));
  });

  testWidgets('QuantityRow avisa cuando no cuadra la custodia', (tester) async {
    await tester.pumpWidget(
      _wrap(
        QuantityRow(
          name: 'Jabón líquido',
          custody: 5,
          returned: 2,
          consumed: 1,
          onReturnedChanged: (_) {},
          onConsumedChanged: (_) {},
        ),
      ),
    );
    expect(
      find.text('Faltan 2. Se registrará una diferencia.'),
      findsOneWidget,
    );
  });

  testWidgets('FilterChips cambia la selección única', (tester) async {
    Set<String>? selected;
    await tester.pumpWidget(
      _wrap(
        FilterChips<String>(
          options: const [
            FilterOption(value: 'hoy', label: 'Hoy', count: 4),
            FilterOption(value: 'semana', label: 'Semana'),
          ],
          selected: const {'hoy'},
          onChanged: (s) => selected = s,
        ),
      ),
    );
    await tester.tap(find.textContaining('Semana'));
    await tester.pump();
    expect(selected, {'semana'});
  });

  testWidgets('SearchField espera el debounce antes de buscar', (tester) async {
    final searches = <String>[];
    await tester.pumpWidget(_wrap(SearchField(onSearch: searches.add)));
    await tester.enterText(find.byType(TextField), 'casa');
    await tester.pump(const Duration(milliseconds: 100));
    expect(searches, isEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    expect(searches, ['casa']);
  });

  testWidgets('TimelineItem y BeforeAfterPair se dibujan', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            const TimelineItem(
              title: 'Limpieza iniciada',
              time: '09:42',
              tone: TimelineTone.info,
              isFirst: true,
            ),
            BeforeAfterPair(before: _pixel, after: _pixel),
          ],
        ),
      ),
    );
    expect(find.text('Limpieza iniciada'), findsOneWidget);
    expect(find.text('ANTES'), findsOneWidget);
    expect(find.text('DESPUÉS'), findsOneWidget);
  });

  testWidgets('DetailScaffold muestra cabecera, banda y pie', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScaffold(
          title: 'Casa Laurel',
          overline: 'LAU-01 · Limpieza',
          subtitle: 'Hoy, 10:00 – 13:00',
          status: const StatusBadge(label: 'Pendiente'),
          banner: const DetailBanner(message: 'Debió iniciar a las 09:00'),
          onBack: () {},
          footer: PrimaryButton(label: 'Iniciar limpieza', onPressed: () {}),
          children: [for (var i = 0; i < 20; i++) Text('Bloque $i')],
        ),
      ),
    );
    expect(find.text('Casa Laurel'), findsWidgets);
    expect(find.text('Debió iniciar a las 09:00'), findsOneWidget);
    expect(find.text('Iniciar limpieza'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar limpieza'), findsOneWidget);
  });
}
