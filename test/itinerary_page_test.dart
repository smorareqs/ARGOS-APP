import 'package:argos_app/features/auth/models/session.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/itinerary/presentation/pages/itinerary_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sesión fija: evita depender del backend en la prueba de la pantalla.
class _SignedIn extends SessionController {
  @override
  AuthState build() => const AuthSignedIn(
    Session(
      user: SessionUser(id: 'u-1', email: 'maria@argos.demo', fullName: 'María Ramos'),
      tenant: ActiveTenant(id: 't-1', name: 'Costa Limpia S.A.'),
      roleKey: 'cleaner',
      roleName: 'Colaborador de limpieza',
      permissions: {'tasks.execute'},
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Hoy muestra la cabecera con la sesión y la semana en curso', (tester) async {
    var openedProfile = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionControllerProvider.overrideWith(_SignedIn.new)],
        child: MaterialApp(
          home: Scaffold(
            body: ItineraryPage(
              today: DateTime(2026, 10, 22), // miércoles
              onOpenProfile: () => openedProfile = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Hola, María'), findsOneWidget);
    expect(find.text('Miércoles 22 de octubre'), findsOneWidget);
    expect(find.text('MR'), findsOneWidget);

    // Semana de domingo 18 a sábado 24, con hoy seleccionado.
    final days = tester.widget<WeekStrip>(find.byType(WeekStrip)).days;
    expect(days.map((d) => d.day), ['18', '19', '20', '21', '22', '23', '24']);
    expect(days.map((d) => d.weekday).join(), 'DLMMJVS');
    expect(days.indexWhere((d) => d.selected), 4);

    // Sin datos de ejemplo: la agenda llega con la fase 2.
    expect(find.byType(TaskCard), findsNothing);
    expect(find.text('Tu agenda aparecerá aquí'), findsOneWidget);

    await tester.tap(find.text('MR'));
    expect(openedProfile, isTrue);
    expect(tester.takeException(), isNull);
  });
}
