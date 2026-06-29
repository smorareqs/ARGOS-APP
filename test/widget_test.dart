import 'package:argos_app/app.dart';
import 'package:argos_app/core/bootstrap/app_bootstrap.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App arranca con pantalla de login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBootstrapProvider.overrideWith((ref) async {}),
        ],
        child: const ArgosApp(),
      ),
    );

    // El router resuelve el redirect inicial (auth guard) de forma asíncrona.
    // Bombeamos varios ciclos hasta que la pantalla de login quede montada,
    // sin usar pumpAndSettle (GoogleFonts deja frames pendientes en test).
    // El router resuelve el redirect inicial (auth guard) de forma asíncrona.
    // Bombeamos varios ciclos hasta que la pantalla de login quede montada.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(LoginPanel).evaluate().isNotEmpty) break;
    }

    // La pantalla de inicio (login teal) está montada con su marca y campos.
    expect(find.byType(LoginPanel), findsOneWidget);
    expect(find.text('ARGOS'), findsOneWidget);
    expect(find.text('CORREO O USUARIO'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });
}
