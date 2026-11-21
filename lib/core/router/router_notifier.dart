import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/shell/models/shell_tab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Guard del router: cada estado de sesión tiene rutas permitidas; cualquier
/// otra redirige a la pantalla de ese estado (ARCHITECTURE.md §10).
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  /// Invitación recibida mientras la app arrancaba o estaba bloqueada.
  String? _pendingInvite;

  static const _signedOutRoutes = {'/login', '/forgot-password', '/invite'};

  String? redirect(GoRouterState state) {
    var location = state.uri;
    if (location.scheme == 'argos') {
      // Deep links: argos://invite?token=… llega con el destino en el host.
      location = switch (location.host) {
        'invite' => Uri(path: '/invite', queryParameters: location.queryParameters),
        _ => Uri(path: '/'),
      };
    }
    final auth = _ref.read(sessionControllerProvider);
    final ready = auth is AuthSignedOut || auth is AuthSignedIn;

    if (location.path == '/invite' && !ready) {
      _pendingInvite = location.toString();
    } else if (_pendingInvite != null && ready) {
      final pending = _pendingInvite!;
      _pendingInvite = null;
      return pending;
    }

    final target = _isAllowed(auth, location.path) ? location.toString() : _homeOf(auth);
    return target == state.uri.toString() ? null : target;
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
