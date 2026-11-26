import 'package:argos_app/core/utils/toast.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Rutas de la app a las que llevan los avisos (`data.app_route`). Las que
/// aún no existen en esta versión muestran un mensaje en lugar de fallar.
const _available = [
  '/tasks/',
  '/tickets',
  '/inventory',
  '/alerts',
  '/notifications',
  '/home/',
  '/profile',
  '/reservations/',
  '/security',
  '/guest',
  '/attendance',
  '/payslips',
  '/chat',
  '/disciplinary',
  '/metrics',
  '/reports',
];

bool isAppRouteAvailable(String route) =>
    _available.any((prefix) => route == prefix || route.startsWith(prefix));

/// Abre la pantalla de un aviso. `/alerts` es la bandeja misma.
void openAppRoute(BuildContext context, String? route) {
  if (route == null || route.isEmpty) return;
  if (route == '/alerts') {
    context.push('/notifications');
    return;
  }
  // Alarmas de salida (seguridad): la pestaña de alarmas.
  if (route == '/security' || route.startsWith('/security/')) {
    context.go('/home/alarms');
    return;
  }
  if (route == '/guest' || route.startsWith('/guest/')) {
    context.go(route);
    return;
  }
  if (!isAppRouteAvailable(route)) {
    showToast(context, 'Esta pantalla llega en una próxima versión de la app.');
    return;
  }
  if (route.startsWith('/home/')) {
    context.go(route);
  } else {
    context.push(route);
  }
}
