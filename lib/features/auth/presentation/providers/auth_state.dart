import 'package:argos_app/features/auth/models/quick_unlock.dart';
import 'package:argos_app/features/auth/models/session.dart';

/// Estado de la sesión. El router deriva de aquí qué pantalla mostrar
/// (ux-ui.md F1 y fichas A1–A10).
sealed class AuthState {
  const AuthState();
}

/// A1: decidiendo a dónde ir.
final class AuthBooting extends AuthState {
  const AuthBooting();
}

/// A10: primer arranque sin conexión y sin sesión guardada.
final class AuthOfflineNoSession extends AuthState {
  const AuthOfflineNoSession();
}

/// A2: sin sesión. [message] explica por qué (p. ej. sesión revocada).
final class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.message});

  final String? message;
}

/// A3: el backend pidió el código TOTP.
final class AuthAwaitingTotp extends AuthState {
  const AuthAwaitingTotp(this.email);

  final String email;
}

/// A4: el usuario tiene varias empresas.
final class AuthChoosingTenant extends AuthState {
  const AuthChoosingTenant({
    required this.memberships,
    this.lastTenantId,
    this.remember = false,
  });

  final List<Membership> memberships;
  final String? lastTenantId;
  final bool remember;
}

/// A5 tras el primer login: ofrecer biometría o PIN.
final class AuthOfferingQuickUnlock extends AuthState {
  const AuthOfferingQuickUnlock(this.session);

  final Session session;
}

/// A6: hay sesión guardada protegida por biometría o PIN.
final class AuthLocked extends AuthState {
  const AuthLocked({required this.settings, this.cached});

  final QuickUnlockSettings settings;

  /// Para saludar al usuario por su nombre antes de desbloquear.
  final Session? cached;
}

/// Sesión abierta. Con [offline] se muestra la caché local.
final class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.session, {this.offline = false, this.cachedAt});

  final Session session;
  final bool offline;
  final DateTime? cachedAt;
}
