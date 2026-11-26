import 'dart:async';

import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/core/network/connectivity_service.dart';
import 'package:argos_app/core/realtime/sign_out_hooks.dart';
import 'package:argos_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:argos_app/features/auth/data/repositories/quick_unlock_repository_impl.dart';
import 'package:argos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:argos_app/features/auth/domain/repositories/quick_unlock_repository.dart';
import 'package:argos_app/features/auth/models/login_outcome.dart';
import 'package:argos_app/features/auth/models/quick_unlock.dart';
import 'package:argos_app/features/auth/models/session.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_controller.g.dart';

const sessionClosedMessage = 'Tu sesión se cerró. Ingresa de nuevo con tu contraseña.';
const pinLockedOutMessage =
    'Demasiados intentos con el PIN. Ingresa con tu contraseña.';
const selectionExpiredMessage = 'La elección de empresa venció. Ingresa de nuevo.';

/// Máquina de estados de la sesión (ux-ui.md F1). Las acciones que vienen de
/// un formulario devuelven el [AppFailure] para mostrarlo junto al campo, o
/// null si salieron bien; la navegación la decide el router según [state].
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  StreamSubscription<void>? _sessionEndedSub;
  StreamSubscription<bool>? _connectivitySub;

  /// Credenciales retenidas en memoria solo mientras se pide el TOTP.
  ({String email, String password})? _pendingTotp;
  String? _selectionToken;

  AuthRepository get _auth => ref.read(authRepositoryProvider);
  QuickUnlockRepository get _quickUnlock => ref.read(quickUnlockRepositoryProvider);

  @override
  AuthState build() {
    _sessionEndedSub = _auth.sessionEnded.listen((_) => _onSessionEnded());
    _connectivitySub = ref
        .read(connectivityServiceProvider)
        .watch()
        .listen(_onConnectivityChanged, onError: (Object _) {});
    ref.onDispose(() {
      _sessionEndedSub?.cancel();
      _connectivitySub?.cancel();
    });
    Future.microtask(boot);
    return const AuthBooting();
  }

  /// A1: con sesión guardada → desbloqueo (A6) o restauración directa; sin
  /// sesión → login, o A10 si además no hay red.
  Future<void> boot() async {
    state = const AuthBooting();
    if (!await _auth.hasStoredSession()) {
      final online = await ref.read(connectivityServiceProvider).hasConnection();
      state = online ? const AuthSignedOut() : const AuthOfflineNoSession();
      return;
    }
    final settings = await _quickUnlock.settings();
    if (settings.enabled) {
      state = AuthLocked(
        settings: settings,
        cached: (await _auth.cachedSession())?.session,
      );
      return;
    }
    await _restore();
  }

  Future<AppFailure?> login(String email, String password) async {
    final result = await _auth.login(email: email, password: password);
    return result.fold(
      (failure) => failure,
      (outcome) => _handleOutcome(outcome, email: email, password: password),
    );
  }

  /// A3: repite el login con el código.
  Future<AppFailure?> submitTotp(String code) async {
    final pending = _pendingTotp;
    if (pending == null) {
      state = const AuthSignedOut();
      return null;
    }
    final result = await _auth.login(
      email: pending.email,
      password: pending.password,
      totpCode: code,
    );
    return result.fold(
      (failure) => failure,
      (outcome) => _handleOutcome(
        outcome,
        email: pending.email,
        password: pending.password,
      ),
    );
  }

  /// Vuelve al login desde A3 o A4.
  void cancelLogin() {
    _pendingTotp = null;
    _selectionToken = null;
    state = const AuthSignedOut();
  }

  /// A4: entra a la empresa elegida.
  Future<AppFailure?> chooseTenant(String tenantId, {required bool remember}) async {
    final token = _selectionToken;
    if (token == null) {
      state = const AuthSignedOut(message: selectionExpiredMessage);
      return null;
    }
    final result = await _auth.completeTenantSelection(
      selectionToken: token,
      tenantId: tenantId,
    );
    return result.fold(
      (failure) {
        if (failure is AuthFailure) {
          cancelLogin();
          state = const AuthSignedOut(message: selectionExpiredMessage);
        }
        return failure;
      },
      (session) async {
        await _auth.saveTenantPreference(lastTenantId: tenantId, remember: remember);
        await _signedInInteractively(session);
        return null;
      },
    );
  }

  /// A8: aceptar invitación. Igual que un login.
  Future<AppFailure?> acceptInvitation({
    required String token,
    required String email,
    required String password,
    String? fullName,
  }) async {
    final result = await _auth.acceptInvitation(
      token: token,
      password: password,
      fullName: fullName,
    );
    return result.fold(
      (failure) => failure,
      (outcome) => _handleOutcome(outcome, email: email, password: password),
    );
  }

  /// Fin de A5 tras el login (configurado u omitido).
  void finishQuickUnlockOffer() {
    if (state case AuthOfferingQuickUnlock(:final session)) {
      state = AuthSignedIn(session);
    }
  }

  /// A6 con PIN.
  Future<PinCheck> unlockWithPin(String pin) async {
    final check = await _quickUnlock.verifyPin(pin);
    switch (check) {
      case PinAccepted():
        await _restore();
      case PinLockedOut():
        await _auth.logout();
        await _quickUnlock.reset();
        state = const AuthSignedOut(message: pinLockedOutMessage);
      case PinRejected():
        break;
    }
    return check;
  }

  /// A6 con biometría. Devuelve si se desbloqueó.
  Future<bool> unlockWithBiometric() async {
    if (!await _quickUnlock.unlockWithBiometric()) return false;
    await _restore();
    return true;
  }

  /// A6 "Usar contraseña": se descarta la sesión guardada.
  Future<void> usePassword() async {
    await _auth.logout();
    await _quickUnlock.reset();
    state = const AuthSignedOut();
  }

  /// Cambiar de empresa desde el perfil, sin cerrar sesión.
  Future<AppFailure?> switchTenant(String tenantId) async {
    final result = await _auth.switchTenant(tenantId);
    return result.fold(
      (failure) async {
        if (failure is AuthFailure) await _endSession(sessionClosedMessage);
        return failure;
      },
      (session) async {
        await _auth.saveTenantPreference(lastTenantId: tenantId);
        state = AuthSignedIn(session);
        return null;
      },
    );
  }

  Future<void> logout() async {
    // Con el token aún vigente: quitar el teléfono de los push, etc.
    await ref.read(signOutHooksProvider).run();
    await _auth.logout();
    await _quickUnlock.reset();
    state = const AuthSignedOut();
  }

  // ── Internos ───────────────────────────────────────────

  Future<AppFailure?> _handleOutcome(
    LoginOutcome outcome, {
    required String email,
    required String password,
  }) async {
    switch (outcome) {
      case LoginNeedsTotp():
        _pendingTotp = (email: email, password: password);
        state = AuthAwaitingTotp(email);
        return null;
      case LoginNeedsTenant(:final selectionToken, :final memberships):
        _pendingTotp = null;
        _selectionToken = selectionToken;
        final preference = await _auth.tenantPreference();
        final remembered = preference.lastTenantId;
        if (preference.remember &&
            memberships.any((m) => m.tenantId == remembered)) {
          // "Recordar mi elección": entra directo a la última empresa. Si
          // falla por red, se muestra la lista; si la selección venció,
          // chooseTenant ya volvió al login.
          final failure = await chooseTenant(remembered!, remember: true);
          if (failure == null || state is AuthSignedOut) return failure;
        }
        state = AuthChoosingTenant(
          memberships: memberships,
          lastTenantId: remembered,
          remember: preference.remember,
        );
        return null;
      case LoginAuthenticated(:final session):
        await _auth.saveTenantPreference(lastTenantId: session.tenant.id);
        await _signedInInteractively(session);
        return null;
    }
  }

  /// Tras escribir la contraseña: ofrecer el inicio rápido si aún no está
  /// configurado ni fue rechazado.
  Future<void> _signedInInteractively(Session session) async {
    _pendingTotp = null;
    _selectionToken = null;
    final settings = await _quickUnlock.settings();
    state = settings.enabled || settings.declined
        ? AuthSignedIn(session)
        : AuthOfferingQuickUnlock(session);
  }

  /// Renueva el token y recarga la sesión. Sin red, entra con la caché.
  Future<void> _restore() async {
    final result = await _auth.restoreSession();
    await result.fold(
      (failure) async {
        if (failure is AuthFailure) {
          await _quickUnlock.reset();
          state = const AuthSignedOut(message: sessionClosedMessage);
          return;
        }
        final cached = await _auth.cachedSession();
        if (cached != null) {
          state = AuthSignedIn(
            cached.session,
            offline: true,
            cachedAt: cached.savedAt,
          );
        } else {
          state = failure is NetworkFailure
              ? const AuthOfflineNoSession()
              : AuthSignedOut(message: failure.message);
        }
      },
      (session) async => state = AuthSignedIn(session),
    );
  }

  Future<void> _endSession(String message) async {
    await _quickUnlock.reset();
    state = AuthSignedOut(message: message);
  }

  void _onSessionEnded() {
    if (state is AuthSignedIn) unawaited(_endSession(sessionClosedMessage));
  }

  /// Al volver la red, la sesión sin conexión se refresca sola.
  void _onConnectivityChanged(bool online) {
    if (state case AuthSignedIn(offline: true) when online) {
      unawaited(_restore());
    }
  }
}
