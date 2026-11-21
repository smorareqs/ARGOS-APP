import 'package:argos_app/core/storage/secure_storage_service.dart';
import 'package:argos_app/features/auth/data/datasources/session_local_datasource.dart';
import 'package:argos_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:argos_app/features/auth/data/repositories/quick_unlock_repository_impl.dart';
import 'package:argos_app/features/auth/models/quick_unlock.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/harness.dart';

void main() {
  late Harness harness;
  late ProviderContainer container;
  SessionController controller() => container.read(sessionControllerProvider.notifier);
  AuthState state() => container.read(sessionControllerProvider);

  /// Inicia sesión como [email] y deja la sesión abierta (omitiendo A5).
  Future<void> signIn(String email) async {
    expect(await controller().login(email, demoPassword), isNull);
    if (state() is AuthOfferingQuickUnlock) controller().finishQuickUnlockOffer();
    expect(state(), isA<AuthSignedIn>());
  }

  /// Simula cerrar y volver a abrir la app conservando el almacenamiento.
  Future<AuthState> restartApp() async {
    final storage = container.read(secureStorageServiceProvider);
    final refresh = await storage.readRefreshToken();
    final pinHash = await storage.readPinHash();
    final biometric = await storage.readBiometricEnabled();
    final cached = await container.read(authRepositoryProvider).cachedSession();
    container.dispose();

    harness = Harness(
      storage: {
        'refresh_token': ?refresh,
        'pin_hash': ?pinHash,
        if (biometric) 'biometric_enabled': 'true',
      },
      biometricAvailable: harness.biometrics.available,
      online: harness.connectivity.online,
    );
    container = harness.container();
    if (cached != null) {
      // La caché de Drift vive en memoria en las pruebas: se reconstruye.
      await container.read(sessionLocalDataSourceProvider).save(cached.session);
    }
    return booted(container);
  }

  setUp(() {
    harness = Harness();
    container = harness.container();
  });

  group('arranque (A1)', () {
    test('sin sesión y con red → login', () async {
      expect(await booted(container), isA<AuthSignedOut>());
    });

    test('sin sesión y sin red → A10', () async {
      harness = Harness(online: false);
      container = harness.container();
      expect(await booted(container), isA<AuthOfflineNoSession>());
    });
  });

  group('inicio de sesión', () {
    setUp(() async => booted(container));

    test('primer login ofrece el inicio rápido y luego entra', () async {
      expect(await controller().login('ana@argos.demo', demoPassword), isNull);
      final offer = state() as AuthOfferingQuickUnlock;
      expect(offer.session.roleKey, 'cleaner');

      controller().finishQuickUnlockOffer();
      expect((state() as AuthSignedIn).session.user.firstName, 'Ana');
    });

    test('credenciales incorrectas devuelven el error y no cambian el estado', () async {
      final failure = await controller().login('ana@argos.demo', 'mala');
      expect(failure?.message, 'Correo o contraseña incorrectos.');
      expect(state(), isA<AuthSignedOut>());
    });

    test('TOTP: pide el código y lo valida', () async {
      expect(await controller().login('admin@argos.demo', demoPassword), isNull);
      expect(state(), isA<AuthAwaitingTotp>());

      final wrong = await controller().submitTotp('000000');
      expect(wrong?.message, 'El código de verificación no es correcto.');
      expect(state(), isA<AuthAwaitingTotp>());

      expect(await controller().submitTotp('123456'), isNull);
      expect(state(), isA<AuthOfferingQuickUnlock>());
    });

    test('varias empresas: elegir y recordar la elección', () async {
      expect(await controller().login('sofia@argos.demo', demoPassword), isNull);
      final choosing = state() as AuthChoosingTenant;
      expect(choosing.memberships, hasLength(2));

      final garrent = choosing.memberships.firstWhere((m) => m.tenantName == 'Garrent');
      expect(await controller().chooseTenant(garrent.tenantId, remember: true), isNull);
      controller().finishQuickUnlockOffer();
      expect((state() as AuthSignedIn).session.tenant.name, 'Garrent');

      // Siguiente login: entra directo a Garrent sin pasar por A4.
      await controller().logout();
      expect(await controller().login('sofia@argos.demo', demoPassword), isNull);
      final signedIn = state();
      final session = signedIn is AuthOfferingQuickUnlock
          ? signedIn.session
          : (signedIn as AuthSignedIn).session;
      expect(session.tenant.name, 'Garrent');
    });

    test('cambiar de empresa sin cerrar sesión', () async {
      expect(await controller().login('sofia@argos.demo', demoPassword), isNull);
      final choosing = state() as AuthChoosingTenant;
      final costa = choosing.memberships.firstWhere((m) => m.tenantName != 'Garrent');
      final garrent = choosing.memberships.firstWhere((m) => m.tenantName == 'Garrent');
      await controller().chooseTenant(costa.tenantId, remember: false);
      controller().finishQuickUnlockOffer();

      expect(await controller().switchTenant(garrent.tenantId), isNull);
      final session = (state() as AuthSignedIn).session;
      expect(session.tenant.name, 'Garrent');
      expect(session.roleKey, 'admin');
    });

    test('cerrar sesión vuelve al login y borra la sesión', () async {
      await signIn('ana@argos.demo');
      await controller().logout();
      expect(state(), isA<AuthSignedOut>());
      expect(await container.read(authRepositoryProvider).hasStoredSession(), isFalse);
    });
  });

  group('arranques siguientes', () {
    test('sin inicio rápido: renueva y entra directo', () async {
      await booted(container);
      await signIn('ana@argos.demo');
      final restarted = await restartApp();
      expect(restarted, isA<AuthSignedIn>());
      expect((restarted as AuthSignedIn).offline, isFalse);
    });

    test('sin red: entra con la caché en modo sin conexión y se refresca al volver la red', () async {
      await booted(container);
      await signIn('ana@argos.demo');
      harness.connectivity.online = false;
      harness.backend.offline = true;

      // El backend simulado se crea de nuevo al reiniciar: se marca sin red.
      final storage = container.read(secureStorageServiceProvider);
      final refresh = await storage.readRefreshToken();
      final cached = await container.read(authRepositoryProvider).cachedSession();
      container.dispose();
      harness = Harness(storage: {'refresh_token': refresh!}, online: false);
      harness.backend.offline = true;
      container = harness.container();
      await container.read(sessionLocalDataSourceProvider).save(cached!.session);

      final offline = await booted(container) as AuthSignedIn;
      expect(offline.offline, isTrue);
      expect(offline.session.user.email, 'ana@argos.demo');

      harness.backend.offline = false;
      harness.connectivity.set(true);
      final online = await waitForState(
        container,
        (s) => s is AuthSignedIn && !s.offline,
      );
      expect(online, isA<AuthSignedIn>());
    });

    test('con PIN: bloquea, rechaza, desbloquea', () async {
      await booted(container);
      await signIn('ana@argos.demo');
      await container.read(quickUnlockRepositoryProvider).setPin('482915');

      final locked = await restartApp() as AuthLocked;
      expect(locked.settings.pinEnabled, isTrue);
      expect(locked.cached?.user.firstName, 'Ana');

      final rejected = await controller().unlockWithPin('000000');
      expect(rejected, isA<PinRejected>());
      expect((rejected as PinRejected).remainingAttempts, 2);
      expect(state(), isA<AuthLocked>());

      expect(await controller().unlockWithPin('482915'), isA<PinAccepted>());
      expect(state(), isA<AuthSignedIn>());
    });

    test('tres PIN incorrectos exigen la contraseña', () async {
      await booted(container);
      await signIn('ana@argos.demo');
      await container.read(quickUnlockRepositoryProvider).setPin('482915');
      await restartApp();

      await controller().unlockWithPin('000000');
      await controller().unlockWithPin('000001');
      expect(await controller().unlockWithPin('000002'), isA<PinLockedOut>());

      final signedOut = state() as AuthSignedOut;
      expect(signedOut.message, pinLockedOutMessage);
      expect(await container.read(authRepositoryProvider).hasStoredSession(), isFalse);
      expect((await container.read(quickUnlockRepositoryProvider).settings()).enabled, isFalse);
    });

    test('con biometría: desbloquea sin PIN', () async {
      harness = Harness(biometricAvailable: true);
      container = harness.container();
      await booted(container);
      await signIn('ana@argos.demo');
      expect(await container.read(quickUnlockRepositoryProvider).enableBiometric(), isTrue);

      final locked = await restartApp() as AuthLocked;
      expect(locked.settings.biometricEnabled, isTrue);
      expect(await controller().unlockWithBiometric(), isTrue);
      expect(state(), isA<AuthSignedIn>());
    });

    test('sesión revocada en otro dispositivo → login con mensaje', () async {
      await booted(container);
      await signIn('ana@argos.demo');
      final storage = container.read(secureStorageServiceProvider);
      final refresh = await storage.readRefreshToken();
      // Revocarla (el backend simulado la recuerda) y reponer el token local.
      await container.read(authRepositoryProvider).logout();
      await storage.writeRefreshToken(refresh!);

      await controller().boot();
      final signedOut = await waitForState(container, (s) => s is AuthSignedOut) as AuthSignedOut;
      expect(signedOut.message, sessionClosedMessage);
    });
  });

  test('si la sesión termina en segundo plano vuelve al login', () async {
    await booted(container);
    await signIn('ana@argos.demo');
    final storage = container.read(secureStorageServiceProvider);
    final refresh = await storage.readRefreshToken();
    await container.read(authRepositoryProvider).logout();
    await storage.writeRefreshToken(refresh!);
    expect(state(), isA<AuthSignedIn>(), reason: 'la app sigue abierta');

    // La próxima petición no puede renovar el token.
    await container.read(authRepositoryProvider).activeSessions();
    final signedOut = await waitForState(container, (s) => s is AuthSignedOut) as AuthSignedOut;
    expect(signedOut.message, sessionClosedMessage);
  });
}
