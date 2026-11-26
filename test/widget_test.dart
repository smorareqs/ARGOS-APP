import 'package:argos_app/app.dart';
import 'package:argos_app/core/router/app_router.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/harness.dart';

/// Avanza la UI sin `pumpAndSettle` (los esqueletos y spinners animan sin fin).
///
/// Entre cuadros deja correr unos milisegundos de tiempo real: el login pasa
/// por E/S real (Drift en memoria, almacenamiento seguro simulado, carga de
/// fuentes) que el reloj falso de las pruebas no hace avanzar por sí solo.
Future<void> settle(WidgetTester tester, {int frames = 30}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  }
}

Future<ProviderContainer> startApp(WidgetTester tester, Harness harness) async {
  final container = harness.container();
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const ArgosApp()));
  await settle(tester);
  return container;
}

Future<void> login(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.text('Iniciar sesión'));
  await settle(tester);
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('sin sesión, la app arranca en el login', (tester) async {
    await startApp(tester, Harness());

    expect(find.byType(LoginPanel), findsOneWidget);
    expect(find.text('CORREO ELECTRÓNICO'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });

  testWidgets('huésped: del login entra con su código a Mi reserva y sale', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await startApp(tester, Harness(now: DateTime.now()));

    await tester.tap(find.text('Soy huésped, tengo un código'));
    await settle(tester);
    expect(find.text('Bienvenido'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'huesped-cst');
    await tester.enterText(find.byType(TextFormField).at(1), 'tomas.reyes@correo.sv');
    await tester.tap(find.text('Entrar'));
    await settle(tester);

    expect(find.text('Hola, Tomás'), findsOneWidget);
    expect(find.text('Áreas comunes'), findsOneWidget);
    await tester.tap(find.text('Ayuda').last);
    await settle(tester);
    await tester.tap(find.text('Cerrar sesión de huésped'));
    await settle(tester);
    await tester.tap(find.text('Cerrar sesión').last);
    await settle(tester);
    expect(find.byType(LoginPanel), findsOneWidget);
  });

  testWidgets('credenciales incorrectas se muestran bajo el formulario', (tester) async {
    await startApp(tester, Harness());
    await login(tester, 'ana@argos.demo', 'mala');

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.byType(LoginPanel), findsOneWidget);
  });

  testWidgets('login → "Ahora no" → pestañas del rol → perfil → cerrar sesión', (tester) async {
    await startApp(tester, Harness());
    await login(tester, 'ana@argos.demo', demoPassword);

    // A5: sin biometría en el dispositivo solo se ofrece el PIN.
    expect(find.text('Entra más rápido la próxima vez'), findsOneWidget);
    expect(find.byType(BiometricPrompt), findsNothing);
    await tester.tap(find.text('Ahora no'));
    await settle(tester);

    // Shell de cleaner (ux-ui.md §4.1).
    for (final label in ['Hoy', 'Semana', 'Inventario', 'Alertas', 'Perfil']) {
      expect(find.widgetWithText(NavTabItem, label), findsOneWidget, reason: label);
    }
    expect(find.text('Hola, Ana'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavTabItem, 'Perfil'));
    await settle(tester);
    expect(find.text('Ana López'), findsOneWidget);
    expect(find.text('Colaborador de limpieza · Costa Limpia S.A.'), findsOneWidget);
    expect(find.text('Cambiar de empresa'), findsNothing, reason: 'solo tiene una empresa');

    // El perfil ya trae la tarjeta de trabajo; fijamos el scrollable antes
    // de desplazar para no perderlo cuando "Ana López" salga de pantalla.
    final profileScroll = find.ancestor(of: find.text('Ana López'), matching: find.byType(Scrollable)).first.evaluate().single.widget;
    await tester.scrollUntilVisible(find.text('Cerrar sesión'), 200, scrollable: find.byWidget(profileScroll));
    await tester.pump();
    await tester.tap(find.text('Cerrar sesión'));
    await settle(tester);
    await tester.tap(find.widgetWithText(DangerButton, 'Cerrar sesión'));
    await settle(tester);

    expect(find.byType(LoginPanel), findsOneWidget);
  });

  testWidgets('supervisor con dos empresas elige empresa y ve "Más"', (tester) async {
    await startApp(tester, Harness());
    await login(tester, 'sofia@argos.demo', demoPassword);

    expect(find.text('Elige la empresa'), findsOneWidget);
    await tester.tap(find.text('Costa Limpia S.A.'));
    await settle(tester);
    await tester.tap(find.text('Ahora no'));
    await settle(tester);

    for (final label in ['Hoy', 'Equipo', 'Reservas', 'Alertas', 'Más']) {
      expect(find.widgetWithText(NavTabItem, label), findsOneWidget, reason: label);
    }
  });

  testWidgets('el deep link de invitación abre A8', (tester) async {
    final container = await startApp(tester, Harness());

    container.read(appRouterProvider).go('argos://invite?token=demo-nuevo');
    await settle(tester);

    expect(find.text('Costa Limpia S.A. te invitó'), findsOneWidget);
    expect(find.text('Crear mi cuenta'), findsOneWidget);
  });
}
