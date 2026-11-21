import 'package:argos_app/features/auth/models/session.dart';

/// Destinos de la barra inferior (ux-ui.md §4.1).
enum ShellTab {
  today('today', 'Hoy'),
  week('week', 'Semana'),
  tickets('tickets', 'Tickets'),
  inventory('inventory', 'Inventario'),
  team('team', 'Equipo'),
  reservations('reservations', 'Reservas'),
  security('security', 'Seguridad'),
  alarms('alarms', 'Alarmas'),
  sharedAreas('areas', 'Áreas'),
  alerts('alerts', 'Alertas'),
  properties('properties', 'Mis propiedades'),
  reports('reports', 'Reportes'),
  more('more', 'Más'),
  profile('profile', 'Perfil');

  const ShellTab(this.id, this.label);

  /// Segmento de ruta: `/home/<id>`.
  final String id;
  final String label;
}

/// Pestañas de la sesión: por rol y bandera del tenant. Un destino marcado
/// con * en ux-ui.md §4.1 solo existe si la bandera está activa.
List<ShellTab> tabsForSession(Session session) => tabsFor(
  roleKey: session.roleKey,
  permissions: session.permissions,
  features: session.tenant.features,
);

List<ShellTab> tabsFor({
  required String roleKey,
  required Set<String> permissions,
  required Map<String, bool> features,
}) {
  bool flag(String key) => features[key] ?? false;

  return switch (roleKey) {
    'cleaner' => const [
      ShellTab.today,
      ShellTab.week,
      ShellTab.inventory,
      ShellTab.alerts,
      ShellTab.profile,
    ],
    'maintenance' => const [
      ShellTab.today,
      ShellTab.tickets,
      ShellTab.inventory,
      ShellTab.alerts,
      ShellTab.profile,
    ],
    'supervisor' || 'admin' => [
      ShellTab.today,
      ShellTab.team,
      if (flag('reservations') && permissions.contains('reservations.read'))
        ShellTab.reservations,
      ShellTab.alerts,
      ShellTab.more,
    ],
    'security' => [
      ShellTab.security,
      ShellTab.alarms,
      if (flag('shared_areas')) ShellTab.sharedAreas,
      ShellTab.alerts,
      ShellTab.profile,
    ],
    'owner' => const [ShellTab.properties, ShellTab.reports, ShellTab.profile],
    _ => _fromPermissions(permissions),
  };
}

/// Roles personalizados del tenant: los destinos salen de sus permisos.
List<ShellTab> _fromPermissions(Set<String> permissions) => [
  if (permissions.contains('tasks.execute') || permissions.contains('tasks.read'))
    ShellTab.today,
  if (permissions.contains('tasks.assign')) ShellTab.team,
  if (permissions.contains('security.dashboard')) ShellTab.security,
  ShellTab.alerts,
  ShellTab.profile,
];
