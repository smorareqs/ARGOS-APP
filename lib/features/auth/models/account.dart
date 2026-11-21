/// Sesión abierta en un dispositivo (B18).
class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.platform,
    required this.lastUsedAt,
    required this.current,
    this.deviceName,
  });

  final String id;

  /// `android`, `ios` o `web`.
  final String platform;
  final String? deviceName;
  final DateTime lastUsedAt;

  /// Es la sesión de este dispositivo.
  final bool current;
}

/// Datos de una invitación pendiente (A8).
class InvitationInfo {
  const InvitationInfo({
    required this.tenantName,
    required this.roleName,
    required this.email,
    required this.userExists,
  });

  final String tenantName;
  final String roleName;
  final String email;

  /// El correo ya tiene cuenta: se acepta con la contraseña actual.
  final bool userExists;
}

/// Preferencia de empresa en A4: la última usada y si saltar la elección.
class TenantPreference {
  const TenantPreference({this.lastTenantId, this.remember = false});

  final String? lastTenantId;
  final bool remember;
}
