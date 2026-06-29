import 'package:argos_app/features/auth/models/usuario_entity.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:argos_app/features/itinerary/presentation/pages/itinerary_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Notifier de auth falso — evita abrir la base de datos real en el test.
class _FakeAuth extends Auth {
  @override
  Future<UsuarioEntity?> build() async => const UsuarioEntity(
        id: 1,
        codigo: 'mr',
        nombre: 'María Ramos',
        activo: true,
      );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Itinerario renderiza header, tareas y navegación', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_FakeAuth.new)],
        child: const MaterialApp(home: ItineraryPage()),
      ),
    );
    await tester.pump();

    // Header con saludo por defecto (sin usuario en sesión).
    expect(find.text('Hola, María'), findsOneWidget);
    expect(find.text('Agenda de hoy', skipOffstage: false), findsOneWidget);

    // Componentes del design system presentes.
    expect(find.byType(ItineraryHeader), findsOneWidget);
    expect(find.byType(WeekStrip), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(TaskCard, skipOffstage: false), findsNWidgets(4));

    // Sin overflow ni excepciones de render.
    expect(tester.takeException(), isNull);
  });
}
