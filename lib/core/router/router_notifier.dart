import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/guest/presentation/providers/guest_session.dart';
import 'package:argos_app/features/shell/models/shell_tab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Guard del router: cada estado de sesión tiene rutas permitidas; cualquier
/// otra redirige a la pantalla de ese estado (ARCHITECTURE.md §10).
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
    _ref.listen(guestSessionProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  /// Invitación o enlace de huésped recibido mientras la app arrancaba.
  String? _pending;

  static const _signedOutRoutes = {'/login', '/forgot-password', '/invite', '/guest-login'};

  String? redirect(GoRouterState state) {
    var location = state.uri;
    if (location.scheme == 'argos') {
      // Deep links: argos://invite?token=… llega con el destino en el host.
      location = switch (location.host) {
        'invite' => Uri(path: '/invite', queryParameters: location.queryParameters),
        // argos://guest?token=… (correo de la reserva) → acceso de huésped.
        'guest' => Uri(path: '/guest-login', queryParameters: location.queryParameters),
        _ => Uri(path: '/'),
      };
    }
    final auth = _ref.read(sessionControllerProvider);
    final guest = _ref.read(guestSessionProvider);
    final ready = auth is AuthSignedIn || (auth is AuthSignedOut && guest is! GuestLoading);
    final isLink = location.path == '/invite' || location.path == '/guest-login';

    if (isLink && location.queryParameters.containsKey('token') && !ready) {
      _pending = location.toString();
    } else if (_pending != null && ready) {
      final pending = _pending!;
      _pending = null;
      return pending;
    }

    final String target;
    if (auth is AuthSignedOut) {
      target = _guestTarget(guest, location);
    } else {
      target = _isAllowed(auth, location.path) ? location.toString() : _homeOf(auth);
    }
    return target == state.uri.toString() ? null : target;
  }

  /// Sin sesión del personal manda la del huésped: con una activa, su
  /// zona (`/guest…`); si terminó con un motivo, A9 lo muestra.
  static String _guestTarget(GuestState guest, Uri location) {
    final path = location.path;
    final guestArea = path == '/guest' || path.startsWith('/guest/');
    return switch (guest) {
      GuestLoading() => '/splash',
      GuestActive() => guestArea ? location.toString() : '/guest',
      GuestNone(:final message) =>
        _signedOutRoutes.contains(path)
            ? location.toString()
            : (guestArea && message != null ? '/guest-login' : '/login'),
    };
  }

  static bool _isAllowed(AuthState auth, String path) {
    return switch (auth) {
      AuthBooting() => path == '/splash',
      AuthOfflineNoSession() => path == '/offline',
      AuthSignedOut() => _signedOutRoutes.contains(path),
      AuthAwaitingTotp() => path == '/login/totp',
      AuthChoosingTenant() => path == '/select-tenant',
      AuthOfferingQuickUnlock() => path == '/quick-unlock',
      AuthLocked() => path == '/unlock',
      AuthSignedIn(:final session) =>
        path == '/invite' ||
            path == '/sync' ||
            path == '/profile' ||
            path.startsWith('/profile/') ||
            path.startsWith('/tasks/') ||
            path == '/inventory' ||
            path == '/notifications' ||
            path == '/alerts' ||
            path == '/tickets' ||
            path.startsWith('/tickets/') ||
            path.startsWith('/reservations/') ||
            path.startsWith('/guests/') ||
            path == '/attendance' ||
            path == '/payslips' ||
            path == '/disciplinary' ||
            path.startsWith('/disciplinary/') ||
            path == '/metrics' ||
            path == '/metrics/team' ||
            path == '/reports' ||
            tabsForSession(session).any((t) => path == '/home/${t.id}'),
    };
  }

  static String _homeOf(AuthState auth) {
    return switch (auth) {
      AuthBooting() => '/splash',
      AuthOfflineNoSession() => '/offline',
      AuthSignedOut() => '/login',
      AuthAwaitingTotp() => '/login/totp',
      AuthChoosingTenant() => '/select-tenant',
      AuthOfferingQuickUnlock() => '/quick-unlock',
      AuthLocked() => '/unlock',
      AuthSignedIn(:final session) => '/home/${tabsForSession(session).first.id}',
    };
  }
}
