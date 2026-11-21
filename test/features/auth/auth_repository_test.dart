import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/core/storage/secure_storage_service.dart';
import 'package:argos_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:argos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:argos_app/features/auth/models/login_outcome.dart';
import 'package:argos_app/features/auth/models/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/harness.dart';

T _right<T>(Either<AppFailure, T> result) =>
    result.fold((f) => fail('se esperaba éxito: ${f.message}'), (v) => v);

AppFailure _left<T>(Either<AppFailure, T> result) =>
    result.fold((f) => f, (_) => fail('se esperaba un error'));

void main() {
  late Harness harness;
  late ProviderContainer container;
  late AuthRepository repo;

  setUp(() {
    harness = Harness();
    container = harness.container();
    repo = container.read(authRepositoryProvider);
  });

  Future<Session> loginAs(String email) async {
    final outcome = _right(await repo.login(email: email, password: demoPassword));
    return (outcome as LoginAuthenticated).session;
  }

  test('login de una sola empresa abre la sesión y la guarda', () async {
    final session = await loginAs('ana@argos.demo');

    expect(session.user.fullName, 'Ana López');
    expect(session.roleKey, 'cleaner');
    expect(session.tenant.name, 'Costa Limpia S.A.');
    expect(session.can('tasks.execute'), isTrue);
    expect(session.can('users.manage'), isFalse);
    expect(repo.accessToken, isNotNull);
    expect(await repo.hasStoredSession(), isTrue);

    final cached = await repo.cachedSession();
    expect(cached?.session.user.email, 'ana@argos.demo');
    expect(cached?.session.permissions, session.permissions);
    expect(cached?.session.tenant.features['parking'], isTrue);
  });

  test('credenciales incorrectas devuelven el mensaje del servidor', () async {
    final failure = _left(await repo.login(email: 'ana@argos.demo', password: 'mala'));
    expect(failure, isA<AuthFailure>());
    expect(failure.message, 'Correo o contraseña incorrectos.');
    expect(await repo.hasStoredSession(), isFalse);
  });

  test('cinco fallos seguidos bloquean con 429', () async {
    for (var i = 0; i < 5; i++) {
      await repo.login(email: 'luis@argos.demo', password: 'mala');
    }
    final failure = _left(
      await repo.login(email: 'luis@argos.demo', password: demoPassword),
    );
    expect(failure.message, contains('Espera 15 minutos'));
  });

  test('2FA: 428 pide el código; con el código entra', () async {
    final first = _right(await repo.login(email: 'admin@argos.demo', password: demoPassword));
    expect(first, isA<LoginNeedsTotp>());

    final wrong = _left(
      await repo.login(email: 'admin@argos.demo', password: demoPassword, totpCode: '000000'),
    );
    expect(wrong.message, 'El código de verificación no es correcto.');

    final ok = _right(
      await repo.login(email: 'admin@argos.demo', password: demoPassword, totpCode: '123456'),
    );
    expect((ok as LoginAuthenticated).session.roleKey, 'admin');
  });

  test('varias empresas: selección y cambio de empresa', () async {
    final outcome = _right(await repo.login(email: 'sofia@argos.demo', password: demoPassword));
    final needsTenant = outcome as LoginNeedsTenant;
    expect(needsTenant.memberships.map((m) => m.tenantName), containsAll(['Costa Limpia S.A.', 'Garrent']));
    expect(await repo.hasStoredSession(), isFalse, reason: 'sin tokens hasta elegir');

    final garrent = needsTenant.memberships.firstWhere((m) => m.tenantName == 'Garrent');
    final session = _right(
      await repo.completeTenantSelection(
        selectionToken: needsTenant.selectionToken,
        tenantId: garrent.tenantId,
      ),
    );
    expect(session.tenant.name, 'Garrent');
    expect(session.roleKey, 'admin');
    expect(session.hasOtherTenants, isTrue);

    final costa = needsTenant.memberships.firstWhere((m) => m.tenantName != 'Garrent');
    final switched = _right(await repo.switchTenant(costa.tenantId));
    expect(switched.tenant.name, 'Costa Limpia S.A.');
    expect(switched.roleKey, 'supervisor');
  });

  test('restaurar la sesión renueva el token y recarga el perfil', () async {
    await loginAs('ana@argos.demo');
    final restored = _right(await repo.restoreSession());
    expect(restored.user.email, 'ana@argos.demo');
  });

  test('sin red, restaurar devuelve NetworkFailure y conserva la sesión', () async {
    await loginAs('ana@argos.demo');
    harness.backend.offline = true;
    expect(_left(await repo.restoreSession()), isA<NetworkFailure>());
    expect(await repo.hasStoredSession(), isTrue);
    expect(await repo.cachedSession(), isNotNull);
  });

  test('una sesión revocada se borra al restaurar', () async {
    await loginAs('ana@argos.demo');
    // Otro dispositivo cierra "todas las demás" … incluida esta, vía logout.
    final storage = container.read(secureStorageServiceProvider);
    final refresh = await storage.readRefreshToken();
    await repo.logout();
    await storage.writeRefreshToken(refresh!);

    expect(_left(await repo.restoreSession()), isA<AuthFailure>());
    expect(await repo.hasStoredSession(), isFalse);
    expect(await repo.cachedSession(), isNull);
  });

  test('token vencido: se renueva una sola vez aunque haya peticiones simultáneas', () async {
    await loginAs('ana@argos.demo');
    harness.clock.advance(const Duration(minutes: 20));
    harness.backend.requests.clear();

    final results = await Future.wait([repo.activeSessions(), repo.activeSessions()]);
    for (final r in results) {
      expect(_right(r), isNotEmpty);
    }
    expect(harness.backend.requests.where((r) => r == 'POST /auth/refresh'), hasLength(1));
  });

  test('si la renovación falla en segundo plano se avisa que la sesión terminó', () async {
    await loginAs('ana@argos.demo');
    final ended = expectLater(repo.sessionEnded, emits(anything));
    // Se revoca la sesión y vence el token: la siguiente petición no puede renovar.
    final storage = container.read(secureStorageServiceProvider);
    final refresh = await storage.readRefreshToken();
    await repo.logout();
    await storage.writeRefreshToken(refresh!);
    harness.clock.advance(const Duration(minutes: 20));

    expect(_left(await repo.activeSessions()), isA<AuthFailure>());
    await ended;
  });

  test('sesiones activas: lista y revoca', () async {
    await loginAs('ana@argos.demo');
    final sessions = _right(await repo.activeSessions());
    expect(sessions.where((s) => s.current), hasLength(1));
    final other = sessions.firstWhere((s) => !s.current);

    _right(await repo.revokeSession(other.id));
    expect(_right(await repo.activeSessions()).map((s) => s.id), isNot(contains(other.id)));

    _right(await repo.revokeOtherSessions());
    expect(_right(await repo.activeSessions()), hasLength(1));
  });

  test('cambiar contraseña: la actual incorrecta es un error de validación', () async {
    await loginAs('ana@argos.demo');
    final failure = _left(
      await repo.changePassword(currentPassword: 'mala', newPassword: 'nueva-clave-1'),
    );
    expect(failure, isA<ValidationFailure>());
    expect(failure.message, 'La contraseña actual no es correcta.');
    expect(await repo.hasStoredSession(), isTrue, reason: 'no cierra la sesión');

    _right(await repo.changePassword(currentPassword: demoPassword, newPassword: 'nueva-clave-1'));
  });

  test('invitación a una cuenta nueva', () async {
    final info = _right(await repo.invitation('demo-nuevo'));
    expect(info.userExists, isFalse);
    expect(info.tenantName, 'Costa Limpia S.A.');

    final outcome = _right(
      await repo.acceptInvitation(token: 'demo-nuevo', password: 'clave-segura-1', fullName: 'Rosa Ixcot'),
    );
    expect((outcome as LoginAuthenticated).session.user.fullName, 'Rosa Ixcot');

    expect(_left(await repo.invitation('demo-nuevo')).message, 'La invitación venció o ya se usó.');
  });

  test('cerrar sesión borra tokens y caché', () async {
    await loginAs('ana@argos.demo');
    await repo.logout();
    expect(repo.accessToken, isNull);
    expect(await repo.hasStoredSession(), isFalse);
    expect(await repo.cachedSession(), isNull);
  });
}
