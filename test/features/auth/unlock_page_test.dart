import 'package:argos_app/features/auth/models/quick_unlock.dart';
import 'package:argos_app/features/auth/models/session.dart';
import 'package:argos_app/features/auth/presentation/pages/unlock_page.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _Locked extends SessionController {
  final pins = <String>[];

  @override
  AuthState build() => const AuthLocked(
    settings: QuickUnlockSettings(pinEnabled: true),
    cached: Session(
      user: SessionUser(id: 'u-1', email: 'ana@argos.demo', fullName: 'Ana López'),
      tenant: ActiveTenant(id: 't-1', name: 'Costa Limpia S.A.'),
      roleKey: 'cleaner',
      roleName: 'Colaborador de limpieza',
      permissions: {},
    ),
  );

  @override
  Future<PinCheck> unlockWithPin(String pin) async {
    pins.add(pin);
    return PinRejected(3 - pins.length);
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('A6: saluda, pide el PIN e informa los intentos restantes', (tester) async {
    final controller = _Locked();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: UnlockPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Costa Limpia S.A.'), findsOneWidget);
    expect(find.byType(BiometricPrompt), findsNothing, reason: 'biometría no activada');

    await tester.enterText(find.byType(TextField), '111111');
    await tester.pump();
    expect(controller.pins, ['111111']);
    expect(find.text('PIN incorrecto. Te quedan 2 intentos.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '222222');
    await tester.pump();
    expect(find.text('PIN incorrecto. Te queda 1 intento.'), findsOneWidget);
  });
}
