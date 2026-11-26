import 'dart:async';

import 'package:argos_app/core/config/app_config.dart';
import 'package:argos_app/core/push/push_service.dart';
import 'package:argos_app/core/realtime/sign_out_hooks.dart';
import 'package:argos_app/core/router/app_links.dart';
import 'package:argos_app/core/router/app_router.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/notifications/data/notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_providers.g.dart';

@Riverpod(keepAlive: true)
PushService pushService(Ref ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMock || !FirebaseConfig.configured) return const NoopPushService();
  return FirebasePushService();
}

/// Registra el teléfono para push al entrar (y cuando FCM rota el token),
/// lo quita al cerrar sesión, y abre la pantalla del push que se tocó.
@Riverpod(keepAlive: true)
void pushRunner(Ref ref) {
  final push = ref.watch(pushServiceProvider);
  final repo = ref.watch(notificationsRepositoryProvider);
  String? token;
  String? registeredFor;
  String? pendingRoute;

  Future<void> register() async {
    final auth = ref.read(sessionControllerProvider);
    if (auth is! AuthSignedIn || auth.offline) return;
    final key = '${auth.session.user.id}:${auth.session.tenant.id}';
    token ??= await push.start();
    if (token == null || registeredFor == '$key:$token') return;
    try {
      await repo.registerDevice(token!, push.platform);
      registeredFor = '$key:$token';
    } catch (_) {
      // Se reintenta en el próximo cambio de sesión o de red.
    }
  }

  void open(Map<String, String> data) {
    final route = data['app_route'];
    if (route == null) return;
    if (ref.read(sessionControllerProvider) is! AuthSignedIn) {
      pendingRoute = route; // se abre al desbloquear
      return;
    }
    _go(ref, route);
  }

  Future<void> unregister() async {
    final t = token;
    registeredFor = null;
    if (t != null) await repo.removeDevice(t);
  }

  final hooks = ref.read(signOutHooksProvider)..add(unregister);
  ref.listen(sessionControllerProvider, (_, next) {
    if (next is AuthSignedIn) {
      unawaited(register());
      final route = pendingRoute;
      if (route != null) {
        pendingRoute = null;
        Future.microtask(() => _go(ref, route));
      }
    } else if (next is AuthSignedOut) {
      registeredFor = null;
    }
  });
  final refresh = push.tokenRefresh.listen((t) {
    token = t;
    registeredFor = null;
    unawaited(register());
  });
  final opened = push.opened.listen(open);
  unawaited(push.initialOpen().then((data) {
    if (data != null) open(data);
  }));
  unawaited(register());
  ref.onDispose(() {
    refresh.cancel();
    opened.cancel();
    hooks.remove(unregister);
  });
}

void _go(Ref ref, String route) {
  final router = ref.read(appRouterProvider);
  if (route == '/alerts') {
    router.push('/notifications');
  } else if (isAppRouteAvailable(route)) {
    router.push(route);
  }
}
