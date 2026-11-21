import 'package:argos_app/features/dev/presentation/pages/component_catalog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('El catálogo de componentes se dibuja sin desbordes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ComponentCatalogPage()));
    await tester.pump();
    expect(find.text('Componentes'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ver detalle de ejemplo'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ver detalle de ejemplo'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar limpieza'), findsOneWidget);
  });
}
